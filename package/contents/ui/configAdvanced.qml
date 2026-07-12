import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_allowSearch: allowSearchCheckBox.checked
    property alias cfg_firstArtist: firstArtistCheckBox.checked
    property alias cfg_baseUrlLrcLib: baseUrlLrcLibTextField.text
    property alias cfg_baseUrlLrcApi: baseUrlLrcApiTextField.text
    // property alias cfg_baseUrlJellyfin: baseUrlJellyfinTextField.text
    // property alias cfg_baseUrlPlex: baseUrlPlexTextField.text
    property alias cfg_providerPriorities: providerPrioritiesTextField.text
    property alias cfg_maxAttempts: maxAttemptsSpinBox.value

    Kirigami.FormLayout {
        QQC2.TextField {
            id: baseUrlLrcLibTextField
            Kirigami.FormData.label: i18n("LRCLIB Base URL: ")
            placeholderText: "https://lrclib.net"
        }

        QQC2.TextField {
            id: baseUrlLrcApiTextField
            Kirigami.FormData.label: i18n("LrcApi Base URL: ")
            placeholderText: "https://api.lrc.cx"
        }

        // QQC2.TextField {
        //     id: baseUrlJellyfinTextField
        //     Kirigami.FormData.label: i18n("Jellyfin Base URL: ")
        // }

        // QQC2.TextField {
        //     id: baseUrlPlexTextField
        //     Kirigami.FormData.label: i18n("Plex Base URL: ")
        // }

        // this is hopefully temporary, a dropdown type thing would be a lot better
        RowLayout {
            Kirigami.FormData.label: i18n("Lyric providers")

            QQC2.TextField {
                id: providerPrioritiesTextField
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Possibly options (seperated by ','): LRCLIB, LrcApi")
            }
        }

        QQC2.SpinBox {
            id: maxAttemptsSpinBox
            Kirigami.FormData.label: i18n("Max attempts: ")
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
    }
}
