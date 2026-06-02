import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC2
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_useFixedSize: useFixedSizeCheckBox.checked
    property alias cfg_fixedWidth: fixedWidthTextField.text
    property alias cfg_fixedHeight: fixedHeightTextField.text
    property alias cfg_margin: marginSpinBox.value
    property alias cfg_fontFamily: fontFamilyComboBox.currentValue
    property alias cfg_fontSize: fontSizeSpinBox.value
    property alias cfg_fontColor: fontColorButton.color
    property alias cfg_fontBold: fontBoldButton.checked
    property alias cfg_fontItalic: fontItalicButton.checked
    property alias cfg_useCustomBackground: useCustomBackgroundCheckBox.checked
    property alias cfg_backgroundColor: backgroundColorButton.color
    property alias cfg_backgroundRadius: backgroundRadiusSpinBox.value
    property alias cfg_fade: fadeTextField.text
    property alias cfg_noMedia: noMediaTextField.text
    property alias cfg_noLyrics: noLyricsTextField.text
    property alias cfg_offset: offsetTextField.text
    property alias cfg_allowSearch: allowSearchCheckBox.checked
    property alias cfg_firstArtist: firstArtistCheckBox.checked
    property alias cfg_horizontalAlignLeft: horizontalAlignLeftButton.checked
    property alias cfg_horizontalAlignCenter: horizontalAlignCenterButton.checked
    property alias cfg_horizontalAlignRight: horizontalAlignRightButton.checked
    property alias cfg_verticalAlignTop: verticalAlignTopButton.checked
    property alias cfg_verticalAlignCenter: verticalAlignCenterButton.checked
    property alias cfg_verticalAlignBottom: verticalAlignBottomButton.checked
    property alias cfg_apiBaseUrl: apiBaseUrlTextField.text

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Use fixed size: ")

            QQC2.CheckBox {
                id: useFixedSizeCheckBox
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Use this if placing inside of a panel")
            }
        }

        QQC2.TextField {
            id: fixedWidthTextField
            visible: cfg_useFixedSize ? true : false
            Kirigami.FormData.label: i18n("Fixed width: ")
        }

        QQC2.TextField {
            id: fixedHeightTextField
            visible: cfg_useFixedSize ? true : false
            Kirigami.FormData.label: i18n("Fixed height: ")
        }

        QQC2.SpinBox {
            id: marginSpinBox
            Kirigami.FormData.label: i18n("Margin: ")
        }

        QQC2.ComboBox {
            id: fontFamilyComboBox
            Kirigami.FormData.label: i18n("Font family: ")
            model: Qt.fontFamilies()
        }

        QQC2.SpinBox {
            id: fontSizeSpinBox
            Kirigami.FormData.label: i18n("Font size: ")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Font style: ")

            KQC2.ColorButton {
                id: fontColorButton
                Kirigami.FormData.label: i18n("Color: ")
            }
            QQC2.Button {
                id: fontBoldButton
                QQC2.ToolTip {
                    text: i18n("Set lyrics to bold")
                }
                icon.name: "format-text-bold"
                checkable: true
            }
            QQC2.Button {
                id: fontItalicButton
                QQC2.ToolTip {
                    text: i18n("Set lyrics to italic")
                }
                icon.name: "format-text-italic"
                checkable: true
            }
        }

        QQC2.CheckBox {
            id: useCustomBackgroundCheckBox
            Kirigami.FormData.label: i18n("Use custom background: ")
        }

        KQC2.ColorButton {
            id: backgroundColorButton
            visible: cfg_useCustomBackground ? true : false
            Kirigami.FormData.label: i18n("Background color")
        }

        QQC2.SpinBox {
            id: backgroundRadiusSpinBox
            visible: cfg_useCustomBackground ? true : false
            Kirigami.FormData.label: i18n("Background border radius")
        }

        QQC2.TextField {
            id: fadeTextField
            Kirigami.FormData.label: i18n("Fade: ")
        }

        QQC2.TextField {
            id: noMediaTextField
            Kirigami.FormData.label: i18n("No media text: ")
        }

        QQC2.TextField {
            id: noLyricsTextField
            Kirigami.FormData.label: i18n("No lyrics text: ")
        }

        QQC2.TextField {
            id: offsetTextField
            Kirigami.FormData.label: i18n("Lyric Offset: ")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Search fallback (inaccurate): ")

            QQC2.CheckBox {
                id: allowSearchCheckBox
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Allows for lyrics based on a search query rather than exact matches")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("First artist only: ")

            QQC2.CheckBox {
                id: firstArtistCheckBox
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Ignores featured artists while searching for lyrics")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Horizontal alignment: ")

            QQC2.Button {
                id: horizontalAlignLeftButton
                QQC2.ToolTip {
                    text: i18n("Align lyrics to left horizontally")
                }
                icon.name: "align-horizontal-left"
                checkable: true
                onClicked: {
                    cfg_horizontalAlignCenter = false;
                    cfg_horizontalAlignRight = false;
                }
            }
            QQC2.Button {
                id: horizontalAlignCenterButton
                QQC2.ToolTip {
                    text: i18n("Align lyrics to center horizontally")
                }
                icon.name: "align-horizontal-center"
                checkable: true
                onClicked: {
                    cfg_horizontalAlignLeft = false;
                    cfg_horizontalAlignRight = false;
                }
            }
            QQC2.Button {
                id: horizontalAlignRightButton
                QQC2.ToolTip {
                    text: i18n("Align lyrics to right horizontally")
                }
                icon.name: "align-horizontal-right"
                checkable: true
                onClicked: {
                    cfg_horizontalAlignLeft = false;
                    cfg_horizontalAlignCenter = false;
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Vertical alignment: ")

            QQC2.Button {
                id: verticalAlignTopButton
                QQC2.ToolTip {
                    text: i18n("Align lyrics to top vertically")
                }
                icon.name: "align-vertical-top"
                checkable: true
                onClicked: {
                    cfg_verticalAlignCenter = false;
                    cfg_verticalAlignBottom = false;
                }
            }
            QQC2.Button {
                id: verticalAlignCenterButton
                QQC2.ToolTip {
                    text: i18n("Align lyrics to center vertically")
                }
                icon.name: "align-vertical-center"
                checkable: true
                onClicked: {
                    cfg_verticalAlignTop = false;
                    cfg_verticalAlignBottom = false;
                }
            }
            QQC2.Button {
                id: verticalAlignBottomButton
                QQC2.ToolTip {
                    text: i18n("Align lyrics to bottom vertically")
                }
                icon.name: "align-vertical-bottom"
                checkable: true
                onClicked: {
                    cfg_verticalAlignTop = false;
                    cfg_verticalAlignCenter = false;
                }
            }
        }
        QQC2.TextField {
            id: apiBaseUrlTextField
            Kirigami.FormData.label: i18n("URL for custom LRCLIB instance")
        }
    }
}
