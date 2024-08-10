import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.0 as QQLayouts

Kirigami.FormLayout {
    id: generalPage
    signal configurationChanged

    property alias cfg_size: sizeSpinBox.value
    property alias cfg_margin: marginSpinBox.value
    property alias cfg_color: colorButton.color
    property alias cfg_bold: boldButton.checked
    property alias cfg_italic: italicButton.checked
    property alias cfg_alignHorizontalLeft: alignHorizontalLeftButton.checked
    property alias cfg_alignHorizontalCenter: alignHorizontalCenterButton.checked
    property alias cfg_alignHorizontalRight: alignHorizontalRightButton.checked
    property alias cfg_alignVerticalTop: alignVerticalTopButton.checked
    property alias cfg_alignVerticalCenter: alignVerticalCenterButton.checked
    property alias cfg_alignVerticalBottom: alignVerticalBottomButton.checked

    QQC2.SpinBox {
        id: marginSpinBox
        Kirigami.FormData.label: i18n("Margin: ")
    }

    QQC2.SpinBox {
        id: sizeSpinBox
        Kirigami.FormData.label: i18n("Size: ")
    }

    QQLayouts.RowLayout {
        Kirigami.FormData.label: i18n("Color: ")

        KQControls.ColorButton {
            id: colorButton
        }
        QQC2.Button {
            id: boldButton
            QQC2.ToolTip {
                text: i18n("Set lyrics to bold")
            }
            icon.name: "format-text-bold"
            checkable: true
        }
        QQC2.Button {
            id: italicButton
            QQC2.ToolTip {
                text: i18n("Set lyrics to Italic")
            }
            icon.name: "format-text-italic"
            checkable: true
        }
    }

    QQLayouts.RowLayout {
        Kirigami.FormData.label: i18n("Horizontal alignment: ")

        QQC2.Button {
            id: alignHorizontalLeftButton
            QQC2.ToolTip {
                text: i18n("Set lyrics to bold")
            }
            icon.name: "align-horizontal-left"
            checkable: true
            onClicked: {
                cfg_alignHorizontalCenter = false
                cfg_alignHorizontalRight = false
            }
        }
        QQC2.Button {
            id: alignHorizontalCenterButton
            QQC2.ToolTip {
                text: i18n("Set lyrics to Italic")
            }
            icon.name: "align-horizontal-center"
            checkable: true
            onClicked: {
                cfg_alignHorizontalLeft = false
                cfg_alignHorizontalRight = false
            }
        }
        QQC2.Button {
            id: alignHorizontalRightButton
            QQC2.ToolTip {
                text: i18n("Align lyrics to right")
            }
            icon.name: "align-horizontal-right"
            checkable: true
            onClicked: {
                cfg_alignHorizontalLeft = false
                cfg_alignHorizontalCenter = false
            }
        }
    }

    QQLayouts.RowLayout {
        Kirigami.FormData.label: i18n("Vertical alignment: ")

        QQC2.Button {
            id: alignVerticalTopButton
            QQC2.ToolTip {
                text: i18n("Set lyrics to bold")
            }
            icon.name: "align-vertical-top"
            checkable: true
            onClicked: {
                cfg_alignVerticalCenter = false
                cfg_alignVerticalBottom = false
            }
        }
        QQC2.Button {
            id: alignVerticalCenterButton
            QQC2.ToolTip {
                text: i18n("Set lyrics to Italic")
            }
            icon.name: "align-vertical-center"
            checkable: true
            onClicked: {
                cfg_alignVerticalTop = false
                cfg_alignVerticalBottom = false
            }
        }
        QQC2.Button {
            id: alignVerticalBottomButton
            QQC2.ToolTip {
                text: i18n("Align lyrics to right")
            }
            icon.name: "align-vertical-bottom"
            checkable: true
            onClicked: {
                cfg_alignVerticalTop = false
                cfg_alignVerticalCenter = false
            }
        }
    }
}   
