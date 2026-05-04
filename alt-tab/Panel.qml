import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    color: Qt.rgba(0, 0, 0, 0.45)

    ListModel {
        id: windowModel
    }

    Process {
        id: listProc

        stderr: StdioCollector {}

        stdout: StdioCollector {
            onStreamFinished: {
                windowModel.clear()
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (!line)
                        continue
                    var sep = line.indexOf(") ")
                    if (sep < 0)
                        continue
                    var num = parseInt(line.substring(0, sep))
                    var label = line.substring(sep + 2)
                    windowModel.append({
                        "number": num,
                        "label": label
                    })
                }
                if (windowModel.count > 0)
                    listView.currentIndex = 0
                listView.forceActiveFocus()
            }
        }
    }

    Process {
        id: focusProc

        stderr: StdioCollector {}
    }

    function refreshWindows() {
        listProc.command = [pluginApi.pluginDir + "/script", "--list"]
        listProc.running = false
        listProc.running = true
    }

    function focusWindow(number) {
        focusProc.command = [pluginApi.pluginDir + "/script", "--focus", number.toString()]
        focusProc.running = false
        focusProc.running = true
        pluginApi.closePanel(screen)
    }

    Component.onCompleted: refreshWindows()

    MouseArea {
        anchors.fill: parent
        onClicked: pluginApi.closePanel(screen)
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 400
        height: Math.min(cardColumn.implicitHeight + Style.marginM * 2, root.height * 0.7)
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Color.mOutline
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: cardColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Style.marginM
            }
            spacing: Style.marginXS

            NText {
                text: "Windows"
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                Layout.bottomMargin: Style.marginXS
            }

            NText {
                visible: windowModel.count === 0
                text: "No windows on this workspace"
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
            }

            ListView {
                id: listView

                Layout.fillWidth: true
                implicitHeight: contentHeight
                model: windowModel
                interactive: false
                focus: true

                Keys.onEscapePressed: pluginApi.closePanel(screen)
                Keys.onReturnPressed: {
                    if (currentIndex >= 0)
                        root.focusWindow(windowModel.get(currentIndex).number)
                }
                Keys.onTabPressed: currentIndex = (currentIndex + 1) % count

                delegate: Rectangle {
                    required property int index
                    required property int number
                    required property string label

                    property bool hovered: false

                    width: listView.width
                    height: 40
                    radius: Style.radiusS
                    color: (listView.currentIndex === index || hovered) ? Color.mPrimaryContainer : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.marginS
                        anchors.rightMargin: Style.marginS
                        spacing: Style.marginS

                        NText {
                            text: number.toString()
                            color: (listView.currentIndex === index || parent.parent.hovered) ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeXS
                            font.weight: Font.Bold
                            Layout.preferredWidth: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        NText {
                            text: label
                            color: (listView.currentIndex === index || parent.parent.hovered) ? Color.mOnPrimaryContainer : Color.mOnSurface
                            pointSize: Style.fontSizeS
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            parent.hovered = true
                            listView.currentIndex = index
                        }
                        onExited: parent.hovered = false
                        onClicked: root.focusWindow(number)
                    }
                }
            }
        }
    }
}
