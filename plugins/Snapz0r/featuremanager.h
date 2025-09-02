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

#ifndef FEATUREMANAGER_H
#define FEATUREMANAGER_H

#include <QObject>
#include <QThread>

#include "commandrunner.h"

class FeatureManager: public QObject {
    Q_OBJECT

    Q_PROPERTY(CommandRunner* commandRunner MEMBER m_commandRunner NOTIFY commandRunnerChanged)

public:
    FeatureManager();
    ~FeatureManager() = default;

    Q_INVOKABLE void launch(const QString& commonId);
    Q_INVOKABLE bool recheckSupport();
    Q_INVOKABLE bool enabled();
    Q_INVOKABLE bool enable();
    Q_INVOKABLE bool isUnsupported();

private:
    void run();

    bool m_supported;
    bool m_enabled;

    QThread m_thread;
    CommandRunner* m_commandRunner;

signals:
    void commandRunnerChanged();
};

#endif
