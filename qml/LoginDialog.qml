import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Themes 1.3
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtQuick.Controls 2.0 as QQC2
import Snapd 1.0
import Snapz0r 1.0

Dialog {
    id: loginDialog

    TextField {
        id: emailField
        placeholderText: i18n.tr("Ubuntu One E-Mail address")
        inputMethodHints: Qt.ImhEmailCharactersOnly
    }
    TextField {
        id: passwordField
        echoMode: TextInput.Password
        placeholderText: i18n.tr("Password")
    }
    Button {
        text: i18n.tr("Login")
        onClicked: {
            let request = snapClient.login(emailField.text, passwordField.text);
            request.runSync()
        }
    }
    Button {
        text: i18n.tr("Cancel")
        onClicked: {
            PopupUtils.close(loginDialog)
        }
    }
}
