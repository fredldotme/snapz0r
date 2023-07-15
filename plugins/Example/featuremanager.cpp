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
    m_commandRunner->sudo(QStringList{"/usr/bin/zcat", "/proc/config.gz"}, true, &output);

    m_supported = output.contains("CONFIG_SQUASHFS") && output.contains("CONFIG_SQUASHFS_XZ") &&
                  output.contains("CONFIG_SQUASHFS_LZ4") && output.contains("CONFIG_SQUASHFS_LZO");

    return m_supported;
}

bool FeatureManager::enabled()
{
    m_enabled =
            (m_commandRunner->sudo(QStringList{"/usr/bin/test", "-f", "/usr/bin/snap"}, true) == 0);
    return m_enabled;
}

bool FeatureManager::enable()
{
    m_thread.start();

    return true;
}

bool FeatureManager::disable()
{
    return false;
}

void FeatureManager::run()
{
    const QByteArray prefContents = QByteArrayLiteral("Package: *\nPin: release o=UBports,a=focal_-_snapd\nPin-Priority: 3001");
    const QByteArray repoContents = QByteArrayLiteral("deb http://repo.ubports.com/ focal_-_snapd main");

    m_commandRunner->sudo(QStringList{"/usr/bin/mount", "-o", "remount,rw", "/"}, true);

    m_commandRunner->writeFile("/etc/apt/preferences.d/ubports-focal_-_snapd.pref", prefContents);
    m_commandRunner->writeFile("/etc/apt/sources.list.d/ubports-focal_-_snapd.list", repoContents);

    m_commandRunner->sudo(QStringList{"/usr/bin/apt", "update"}, true);

    // These may or may not fail
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/usr/libexec/lxc-android-config/device-hacks"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/etc/profile.d"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/usr/lib/systemd/user"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/lib/udev/rules.d/70-android.rules"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/umount", "/lib/udev/rules.d/99-android.rules"}, true);

    m_commandRunner->sudo(QStringList{"/usr/bin/apt", "install", "-y", "lxc-android-config"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/apt", "install", "-y", "snapd"}, true);

    m_commandRunner->rm("/mnt");
    m_commandRunner->sudo(QStringList{"/usr/bin/mkdir", "/mnt"}, true);
    m_commandRunner->sudo(QStringList{"/usr/bin/mkdir", "/root/snap"}, true);

    m_commandRunner->sudo(QStringList{"/usr/bin/mount", "-o", "remount,ro", "/"}, true);

    m_commandRunner->sudo(QStringList{"/usr/bin/sync"}, true);
    m_commandRunner->sudo(QStringList{"/usr/sbin/reboot"}, true);
}