import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Themes 1.3
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtQuick.Controls 2.0 as QQC2
import Snapz0r 1.0

Page {
    header: PageHeader {
        id: header
        title: i18n.tr("Snapz0r")
        StyleHints {
            foregroundColor: "#ffffff"
            backgroundColor: "#42cba1"
            dividerColor: LomiriColors.slate
        }
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

    Component {
        id: infoDialog

        Dialog {
            id: infoDialogue
            title: qsTr("About Snapz0r")
            text: qsTr("Snapz0r enables support for Snaps on Ubuntu Touch 20.04.") + "\n\n" +
                  qsTr("It depends on features that the system integrator/porter must provide.") + "\n" +
                  qsTr("For proper support make sure to ask your device's maintainer to enable the following kernel defconfig switches:") + "\n\n" +
                  qsTr("CONFIG_SQUASHFS=y") + "\n" +
                  qsTr("CONFIG_SQUASHFS_XZ=y") + "\n" +
                  qsTr("CONFIG_SQUASHFS_LZO=y")

            Button {
                text: qsTr("Ok")
                onClicked: {
                    PopupUtils.close(infoDialogue)
                }
            }
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
                                            "Not available")
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
            text: "Installing... Please keep this app up and running until completed. The device will reboot by itself."
            wrapMode: Text.WordWrap
        }
        Item {
            height: units.gu(4)
        }
    }
}
