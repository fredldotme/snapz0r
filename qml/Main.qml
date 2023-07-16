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
import Example 1.0

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
        PopupUtils.open(dialog);
    }

    property bool checked : false
    property bool supported : false
    property bool featureEnabled : false
    property bool installing : false

    function recheckSupport() {
        supported = FeatureManager.recheckSupport();
        featureEnabled = FeatureManager.enabled();
        checked = true;
    }

    Component {
        id: dialog

        Dialog {
            id: dialogue
            title: qsTr("Authentication required")
            text: qsTr("Please enter your user PIN or password to continue:")

            Connections {
                target: CommandRunner
                onPasswordRequested: {
                    CommandRunner.providePassword(entry.text)
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
            }
            Button {
                text: qsTr("Ok")
                color: theme.palette.normal.positive
                enabled: !enterDelayTimer.running
                onClicked: {
                    if (CommandRunner.validatePassword()) {
                        PopupUtils.close(dialogue)
                        recheckSupport();
                    } else {
                        enterDelayTimer.start()
                    }
                }
            }
            Button {
                text: qsTr("Cancel")
                enabled: !enterDelayTimer.running
                onClicked: {
                    PopupUtils.close(dialogue)
                    Qt.quit()
                }
            }
        }
    }


    Component {
        id: infoDialog

        Dialog {
            id: infoDialogue
            title: qsTr("About Snapz0r")
            text: qsTr("Snapz0r enables preliminary support for Snaps on Ubuntu Touch 20.04.") + "\n\n" +
                  qsTr("For proper support make sure to ask your device's maintainer to enable the following kernel defconfig switches:") + "\n\n" +
                  qsTr("CONFIG_SQUASHFS=y") + "\n" +
                  qsTr("CONFIG_SQUASHFS_XZ=y") + "\n" +
                  qsTr("CONFIG_SQUASHFS_LZO=y") + "\n" +
                  qsTr("CONFIG_SQUASHFS_LZ4=y")

            Connections {
                target: CommandRunner
                onPasswordRequested: {
                    CommandRunner.providePassword(entry.text)
                }
            }

            Button {
                text: qsTr("Ok")
                onClicked: {
                    PopupUtils.close(infoDialogue)
                }
            }
        }
    }

    Page {
        id: mainPage
        header: PageHeader {
            id: header
            title: i18n.tr("Snapz0r")
            trailingActionBar {
                actions: [
                    Action {
                        iconName: "info"
                        text: i18n.tr("Info")
                        onTriggered: {
                            PopupUtils.open(infoDialog)
                        }
                    }
                ]
                numberOfSlots: 1
            }
        }

        Column {
            visible: root.checked && !root.installing
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(1)

            Icon {
                width: Math.min(root.width, root.height) / 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: width
                name: root.featureEnabled ? "tick" : "close"
            }
            Label {
                width: Math.min(root.width, root.height) / 2
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Kernel support: " + (root.supported ?
                                                "Available" :
                                                "Partial")
                wrapMode: Text.WordWrap
            }
            Item {
                height: units.gu(4)
            }
            Row {
                spacing: units.gu(1)
                enabled: !root.featureEnabled
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    text: i18n.tr("Enable Snaps")
                    onClicked: {
                        root.installing = true
                        FeatureManager.enable()
                    }
                }
            }
        }

        Column {
            visible: root.checked && root.installing
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(1)

            QQC2.BusyIndicator {
                width: Math.min(root.width, root.height) / 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: width
                running: root.installing
            }
            Label {
                width: Math.min(root.width, root.height) / 2
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Installing... Please keep this app running up and running until completed. The device will reboot by itself."
                wrapMode: Text.WordWrap
            }
            Item {
                height: units.gu(4)
            }
        }
    }
}
