import QtQuick 2.7
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Themes 1.3
import QtQml.Models 2.12
import Snapd 1.0
import Snapz0r 1.0

Page {
    id: storePage

    property bool refreshing : false
    property var globalRequest : null
    readonly property bool inProgress : (globalRequest !== null) || refreshing

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
                }/*,
                Action {
                    iconName: "history"
                    text: i18n.tr("Changes")
                    onTriggered: {
                        PopupUtils.open(popoverComponent, installedAppsList)
                    }
                }*/
            ]
            numberOfSlots: 1
        }

        QQC2.BusyIndicator {
            height: header.height / 2
            width: height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            running: storePage.inProgress
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
        request = null;
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

    Component {
        id: popoverComponent

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }

                Component.onCompleted: {

                }
            }
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

        onVisibilityChanged: {
            if (!visibility)
                refreshSnapList()
        }

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
                    Label {
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
            property var snapMedia : {
                if (!snap)
                    return [];

                let ret = []
                for (let i = 0; i < 5; i++) {
                    try {
                        console.log("MEDIUM: " + snapDetailsPage.snap.media(i).url)
                        ret.push({
                                     "url": snapDetailsPage.snap.media(i).url,
                                     "width": snapDetailsPage.snap.media(i).width,
                                     "height": snapDetailsPage.snap.media(i).height
                                 })
                    } catch (e) {
                        console.log(e)
                    }
                }
                return ret;
            }

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
                        enabled: globalRequest === null

                        onTriggered: {
                            if (installed) {
                                globalRequest = snapClient.remove(snapDetailsPage.snap.name);
                                mainLayout.removePages(snapDetailsPage);
                            } else {
                                globalRequest = snapClient.install(snapDetailsPage.snap.name);
                            }

                            globalRequest.complete.connect(function(){
                                refreshSnapList();
                                globalRequest = null
                                snapDetailsPage.installed = !isNaN(snapDetailsPage.snap.installDate)
                            });
                            globalRequest.runAsync()
                        }
                    },
                    Action {
                        iconName: "external-link"
                        text: i18n.tr("Website")
                        enabled: snapDetailsPage.snap !== null
                        onTriggered: {
                            Qt.openUrlExternally(snapDetailsPage.snap.website)
                        }
                    },
                    Action {
                        iconName: "ubuntu-store-symbolic"
                        text: i18n.tr("Store Website")
                        enabled: snapDetailsPage.snap !== null
                        onTriggered: {
                            Qt.openUrlExternally("https://snapcraft.io/" + snapDetailsPage.snap.name)
                        }
                    }

                        /*,
                    Action {
                        iconName: "history"
                        text: i18n.tr("Changes")
                        onTriggered: {
                            PopupUtils.open(popoverComponent, installedAppsList)
                        }
                    }*/
                ]
            }

            Column {
                anchors {
                    top: snapDetailsPageHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                spacing: units.gu(2)

                ProgressBar {
                    indeterminate: storePage.inProgress
                    visible: storePage.inProgress
                    width: parent.width
                }

                Row {
                    id: detailsHeader
                    width: parent.width
                    spacing: units.gu(0.5)

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
                        spacing: units.gu(0.5)

                        Label {
                            text: snapDetailsPage.snap.title
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(2)
                        }
                        Label {
                            text: qsTr("By %1").arg(snapDetailsPage.snap.developer)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(1.5)
                        }
                        Label {
                            text: qsTr("License: %1").arg(snapDetailsPage.snap.license)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(1.5)
                        }
                        Label {
                            text: qsTr("Confinement: %1").arg(confinementLevel(snapDetailsPage.snap))
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: contentWidth
                            font.pixelSize: units.gu(1.5)
                            color: confinementColor(snapDetailsPage.snap)
                            function confinementLevel(snap) {
                                switch (snap.confinement) {
                                case SnapdSnap.SnapConfinementStrict:
                                    return qsTr("Strict")
                                case SnapdSnap.SnapConfinementDevmode:
                                    return qsTr("Dev mode")
                                case SnapdSnap.SnapConfinementClassic:
                                    return qsTr("Classic")
                                default:
                                    return qsTr("Unknown!")
                                }
                            }
                            function confinementColor(snap) {
                                switch (snap.confinement) {
                                case SnapdSnap.SnapConfinementStrict:
                                    return theme.palette.normal.positive;
                                case SnapdSnap.SnapConfinementDevmode:
                                case SnapdSnap.SnapConfinementClassic:
                                    return LomiriColors.orange;
                                default:
                                    return LomiriColors.red;
                                }
                            }
                        }
                        /*
                        Button {
                            text: qsTr("Launch")
                            readonly property string app : {
                                let request = snapClient.getApps(snapDetailsPage.snap.name)
                                request.runSync()
                                return request.app(0).name;
                            }
                            enabled: {
                                let request = snapClient.getApps(snapDetailsPage.snap.name)
                                request.runSync()
                                return request.app(0).active;
                            }

                            onClicked: {
                                FeatureManager.launch(snapDetailsPage.snap.name + "_" +
                                                      snapDetailsPage.snap.app(0).name)
                            }
                        }
                        */
                    }
                }
                ListView {
                    id: screenshotsList
                    width: parent.width
                    height: snapDetailsPage.snapMedia.length > 0 ? 256 : 0
                    spacing: units.gu(0.2)
                    flickableDirection: ListView.Horizontal
                    model: snapDetailsPage.snapMedia
                    delegate: Image {
                        fillMode: Image.PreserveAspectFit
                        width: modelData.width
                        height: modelData.height
                        source: modelData.url
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
                        color: LomiriColors.slate
                    }
                }
            }
        }
    }
}
