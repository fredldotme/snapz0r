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

import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Themes 1.3
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtQuick.Controls 2.0 as QQC2
import Snapd 1.0
import Snapz0r 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'snapz0r.fredldotme'
    automaticOrientation: true
    anchorToKeyboard: true

    width: units.gu(45)
    height: units.gu(75)

    Component.onCompleted: {
        FeatureManager.commandRunner = CommandRunner;
        recheckSupport()
        snapClient.setUserAgent("Snapz0r-Ubuntu-Touch")
    }

    property bool checked : false
    property bool supported : false
    property bool featureEnabled : false
    property bool installing : false
    property string password : ""

    function recheckSupport() {
        supported = FeatureManager.recheckSupport();
        featureEnabled = FeatureManager.enabled();
        checked = true;
    }

    Component {
        id: storeComponent
        Store {
            id: store
        }
    }

    Component {
        id: enablementComponent
        Enablement {
            id: enablement
        }
    }

    Component {
        id: dialog

        Dialog {
            id: dialogue
            title: qsTr("Authentication required")
            text: qsTr("Please enter your user PIN or password to continue:")

            function testPassword() {
                root.password = entry.text
                if (CommandRunner.validatePassword()) {
                    PopupUtils.close(dialogue)
                    recheckSupport();
                } else {
                    enterDelayTimer.start()
                }
            }

            Timer {
                id: enterDelayTimer
                interval: 1000
                running: false
                onTriggered: entry.text = ""
            }
            TextField {
                id: entry
                placeholderText: qsTr("PIN or password")
                echoMode: TextInput.Password
                focus: true
                enabled: !enterDelayTimer.running
                onAccepted: dialogue.testPassword()
            }
            Button {
                text: qsTr("Ok")
                color: theme.palette.normal.positive
                enabled: !enterDelayTimer.running
                onClicked: dialogue.testPassword()
            }
            Button {
                text: qsTr("Cancel")
                enabled: !enterDelayTimer.running
                onClicked: {
                    Qt.quit()
                }
            }
        }
    }

    onCheckedChanged: {
        if (!checked)
            return;

        if (featureEnabled) {
            mainLayout.primaryPage = storeComponent.createObject(mainLayout)
        } else {
            mainLayout.primaryPage = enablementComponent.createObject(mainLayout)
            PopupUtils.open(dialog)
        }
    }

    SnapdClient {
        id: snapClient
    }

    Connections {
        target: CommandRunner
        onPasswordRequested: {
            CommandRunner.providePassword(password)
        }
    }

    AdaptivePageLayout {
        id: mainLayout
        anchors.fill: parent
        layouts: [
            PageColumnsLayout {
                when: root.width > root.height
                PageColumn {
                    preferredWidth: units.gu(40)
                }
                PageColumn {
                    fillWidth: true
                }
            },
            PageColumnsLayout {
                when: root.width < root.height
                PageColumn {
                    fillWidth: true
                }
            }
        ]
        primaryPage: Page {
            header: PageHeader {
                title: i18n.tr("Checking functionality...")
            }
        }
    }
}
