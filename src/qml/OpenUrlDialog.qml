/* Copyright 2013-2020 Yikun Liu <cos.lyk@gmail.com>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */
 
import QtQuick 2.7
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import MoonPlayer 1.0

Dialog {
    id: openUrlDialog
    width: (parent.width * 2 / 3)
    height: 210
    title: qsTr("Enter URL to parse")
    standardButtons: Dialog.Ok | Dialog.Cancel
    focus: true

    onAccepted: {
        if (openUrlInput.text !== "")
            PlaylistModel.addUrl(openUrlInput.text, downloadCheckBox.checked);
        openUrlInput.text = "";
    }

    onRejected: openUrlInput.text = ""
    
    Connections {
        target: Dialogs
        onOpenUrlStarted: {
            openUrlInput.text = url
            openUrlDialog.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent

        TextField {
            id: openUrlInput
            selectByMouse: true
            Layout.fillWidth: true
            height: 30
            focus: true
            onAccepted: openUrlDialog.accept()
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                acceptedButtons: Qt.RightButton
                onClicked: {
                    var start = openUrlInput.selectionStart;
                    var end = openUrlInput.selectionEnd;
                    contextMenu.x = mouse.x;
                    contextMenu.y = mouse.y;
                    contextMenu.open();
                    openUrlInput.select(start, end);
                }
            }

            Menu {
                id: contextMenu
                MenuItem {
                    text: "Cu&t"
                    onTriggered: {
                        openUrlInput.cut()
                    }
                }
                MenuItem {
                    text: "&Copy"
                    onTriggered: {
                        openUrlInput.copy()
                    }
                }
                MenuItem {
                    text: "&Paste"
                    onTriggered: {
                        openUrlInput.paste()
                    }
                }
                MenuItem {
                    text: "Paste && Go"
                    onTriggered: {
                        openUrlInput.paste()
                        openUrlDialog.accept()
                    }
                }
                MenuItem {
                    text: "&Delete"
                    onTriggered: {
                        openUrlInput.remove(openUrlInput.selectionStart, openUrlInput.selectionEnd)
                        openUrlInput.deselect()
                    }
                }
                MenuItem {
                    text: "Select &All"
                    onTriggered: {
                        openUrlInput.selectAll()
                    }
                }
            }
        }

        CheckBox {
            id: downloadCheckBox
            text: qsTr("Download video")
        }
    }
}
