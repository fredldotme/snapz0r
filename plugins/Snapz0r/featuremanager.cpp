/*
 * Copyright (C) 2023  Alfred Neumayer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Box64AndWine is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QString>
#include <QVariant>

#include <stdio.h>
#include <unistd.h>

#include <chrono>
#include <thread>

#include "featuremanager.h"

FeatureManager::FeatureManager()
{
    QObject::connect(&m_thread, &QThread::started, this, &FeatureManager::run, Qt::DirectConnection);
}

bool FeatureManager::recheckSupport()
{
    QByteArray output;
    m_commandRunner->shell(QStringList{"/usr/bin/zcat", "/proc/config.gz"}, true, &output);

    m_supported = output.contains("CONFIG_SQUASHFS") && output.contains("CONFIG_SQUASHFS_XZ") &&
                  output.contains("CONFIG_SQUASHFS_LZO");

    return m_supported;
}

bool FeatureManager::enabled()
{
    m_enabled =
            (m_commandRunner->shell(QStringList{"/usr/bin/test", "-f", "/usr/bin/snap"}, true) == 0);
    return m_enabled;
}

bool FeatureManager::enable()
{
    m_thread.start();

    return true;
}

void FeatureManager::run()
{
    m_commandRunner->sudo(QStringList{"/usr/bin/mount", "-o", "remount,rw", "/"}, true);

    // Temporary storage for apt
    m_commandRunner->sudo(QStringList{"/usr/bin/mkdir", "/tmp/apt"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/mount", "-o", "bind", "/tmp/apt", "/var/cache/apt"}, true);

    // Port-dependent, these may or may not fail
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/etc/profile.d"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/usr/lib/systemd/user"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/usr/lib/systemd/system"}, true);

    // Do the thing
    m_commandRunner->sudo(QStringList{"/usr/bin/apt", "update"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/env", "DEBIAN_FRONTEND=noninteractive", "/usr/bin/apt", "install", "--no-install-recommends", "-y", "snapd", "lomiri-polkit-agent"}, true);

    m_commandRunner->sudo(QStringList{"/usr/bin/mount", "-o", "remount,ro", "/"}, true);

    m_commandRunner->sudo(QStringList{"/usr/bin/sync"}, true);
    m_commandRunner->sudo(QStringList{"/usr/sbin/reboot", "-f"}, true);
}
