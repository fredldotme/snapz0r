import QtQuick 2.7
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Themes 1.3
import QtQml.Models 2.12
import Snapz0r 1.0

Page {
    id: storePage

    property bool refreshing : false
    property bool inProgress : false

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
                    iconName: "toolkit_input-search"
                    text: i18n.tr("Search")
                    onTriggered: {
                        searchContextArea.visibility = !searchContextArea.visibility
                    }
                }
            ]
            numberOfSlots: 1
        }
    }

    property var snapList : []
    function refreshSnapList() {
        refreshing = true;
        installedAppsList.model.clear()
        let request = snapClient.list();
        request.runSync()

        for (let i = 0; i < request.snapCount; i++) {
            let snap = request.snap(i);
            console.log(snap.name + ": " + snap.icon)
            installedAppsList.model.append(snap)
        }
        refreshing = false;
    }

    Component.onCompleted: {
        refreshSnapList()
    }

    ProgressBar {
        id: indeterminateBar
        indeterminate: storePage.inProgress
        visible: storePage.inProgress
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
        }
    }

    RowLayout {
        id: searchContextArea
        anchors {
            top: indeterminateBar.bottom
            left: parent.left
            right: parent.right
        }
        property bool visibility : false
        height: visibility ? units.gu(4) : 0
        opacity: visibility ? 1.0 : 0.0
        visible: height > 0
        clip: true

        function startSearch() {
            installedAppsList.model.clear();
            let request = snapClient.find(searchField.text);
            request.runSync()
            for (let i = 0; i < request.snapCount; i++) {
                let snap = request.snap(i);
                console.log(snap.name + ": " + snap.icon)
                installedAppsList.model.append(snap)
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 100
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }

        TextField {
            id: searchField
            placeholderText: i18n.tr("Search for snaps:")
            Layout.fillWidth: true
            focus: searchContextArea.visibility
            onAccepted: searchContextArea.startSearch()
        }

        Button {
            text: i18n.tr("Search")
            color: LomiriColors.orange
            onClicked: searchContextArea.startSearch()
        }
    }

    ListView {
        id: installedAppsList
        anchors {
            top: searchContextArea.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        anchors.margins: units.gu(1)
        model: ListModel { }
        clip: true

        delegate: Component {
            Rectangle {
                height: units.gu(6)
                width: parent.width
                radius: units.gu(1)
                color: mouseArea.pressed ? LomiriColors.lightBlue : "transparent"
                Row {
                    id: entryRoot
                    anchors.fill: parent
                    spacing: units.gu(1)
                    property var snap : installedAppsList.model.get(index)

                    Image {
                        source: entryRoot.snap.icon
                        height: parent.height
                        width: height
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: entryRoot.snap.name
                        verticalAlignment: Text.AlignVCenter
                        height: parent.height
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: {
                        console.log("Details for snap: " + entryRoot.snap.name)
                        storePage.pageStack.addPageToNextColumn(storePage,
                                                                snapDetailsComponent.createObject(storePage,
                                                                                                  { snap: entryRoot.snap }))
                    }
                }
            }
        }
    }

    PullToRefresh {
        parent: installedAppsList
        refreshing: storePage.refreshing
        onRefresh: refreshSnapList()
    }

    Label {
        text: i18n.tr("No Snaps installed yet")
        visible: installedAppsList.model.count < 1
        font.pixelSize: units.gu(3)
        anchors.centerIn: parent
    }

    Component {
        id: snapDetailsComponent
        Page {
            id: snapDetailsPage
            property var snap: null
            property bool installed : !isNaN(snapDetailsPage.snap.installDate)

            Component.onCompleted: {
                console.log("Snap installDate: " + snapDetailsPage.snap.installDate);
            }

            header: PageHeader {
                id: snapDetailsPageHeader
                title: i18n.tr("Details for %1").arg(snapDetailsPage.snap.name)
                StyleHints {
                    foregroundColor: "#ffffff"
                    backgroundColor: "#42cba1"
                    dividerColor: LomiriColors.slate
                }
                leadingActionBar.actions: [
                    Action {
                        iconName: "close"
                        onTriggered: mainLayout.removePages(snapDetailsPage)
                    }
                ]

                trailingActionBar.actions: [
                    Action {
                        iconName: snapDetailsPage.installed ? "delete" : "save"
                        text: snapDetailsPage.installed ? i18n.tr("Remove") : i18n.tr("Install")

                        onTriggered: {
                            if (installed) {
                                let request = snapClient.remove(snapDetailsPage.snap.name);
                                request.complete.connect(function(){
                                    refreshSnapList();
                                    snapDetailsPage.installed = !isNaN(snapDetailsPage.snap.installDate)
                                    storePage.inProgress = false
                                });
                                request.progress.connect(function(){
                                    storePage.inProgress = true
                                });
                                request.runAsync()
                                mainLayout.removePages(snapDetailsPage);
                            } else {
                                let request = snapClient.install(snapDetailsPage.snap.name);
                                request.complete.connect(function(){
                                    refreshSnapList();
                                    snapDetailsPage.installed = !isNaN(snapDetailsPage.snap.installDate)
                                    storePage.inProgress = false
                                });
                                request.progress.connect(function(){
                                    storePage.inProgress = true
                                });
                                request.runAsync()
                            }
                        }
                    }
                ]
            }

            Column {
                anchors {
                    top: snapDetailsPageHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                Row {
                    id: detailsHeader
                    width: parent.width
                    spacing: units.gu(1)

                    Image {
                        id: snapIcon
                        source: snapDetailsPage.snap.icon
                        width: parent.width / 4
                        height: width
                        fillMode: Image.PreserveAspectFit
                    }
                    Column {
                        width: parent.width - snapIcon.width
                        height: snapIcon.height
                        Text {
                            text: snapDetailsPage.snap.title
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(2)
                        }
                        Text {
                            text: qsTr("By %1").arg(snapDetailsPage.snap.developer)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(1.5)
                        }
                        Text {
                            text: qsTr("License: %1").arg(snapDetailsPage.snap.license)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(1.5)
                        }
                    }
                }

                Flickable {
                    id: detailsFlickable
                    width: parent.width
                    height: parent.height - detailsHeader.height
                    contentHeight: description.height
                    clip: true

                    Label {
                        id: description
                        text: snapDetailsPage.snap.description
                        width: parent.width
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: units.gu(2)
                    }
                }
            }
        }
    }
}
