import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#101315"

    property string currentUser: userModel.lastUser
    property int sessionIndex: sessionModel.lastIndex

    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#101315"
        opacity: 0.42
    }

    Column {
        anchors.centerIn: parent
        spacing: 28
        width: Math.min(parent.width * 0.8, 420)

        Image {
            source: "profile.jpg"
            width: 150
            height: 150
            fillMode: Image.PreserveAspectCrop
            smooth: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.currentUser
            color: "white"
            font.family: "SFMono Nerd Font"
            font.pixelSize: 22
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: parent.width
            height: 58
            radius: 12
            color: "#101315"
            opacity: 0.88
            border.width: 1
            border.color: "#40ffffff"

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "\u2022"
                color: "white"
                font.family: "SFMono Nerd Font"
                font.pixelSize: 20
                focus: true

                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(root.currentUser, password.text, root.sessionIndex)
                        event.accepted = true
                    }
                }
            }
        }

        Text {
            text: "Press Enter to unlock"
            color: "white"
            opacity: 0.72
            font.family: "SFMono Nerd Font"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
