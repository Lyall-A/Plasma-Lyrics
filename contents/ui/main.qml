import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtQuick.Window 2.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root
    width: config_width;
    height: config_height;

    preferredRepresentation: fullRepresentation
    Layout.preferredWidth: config_width;
    Layout.preferredHeight: config_height;

    Mpris.Mpris2Model {
        id: mpris2Model
    }

    // Player info
    property string title: mpris2Model.currentPlayer?.track ?? "";
    property string artist: mpris2Model.currentPlayer?.artist ?? "";
    property string album: mpris2Model.currentPlayer?.album ?? "";
    property string playerName: mpris2Model.currentPlayer?.objectName ?? "";
    property int position: mpris2Model.currentPlayer?.position ?? 0;

    // Global constants
    readonly property string lrclibBaseUrl: "https://lrclib.net";

    // Configs
    property int config_width: Plasmoid.configuration.width;
    property int config_height: Plasmoid.configuration.height;
    property int config_size: Plasmoid.configuration.size;
    property int config_margin: Plasmoid.configuration.margin;
    property string config_color: Plasmoid.configuration.color;
    property bool config_bold: Plasmoid.configuration.bold;
    property bool config_italic: Plasmoid.configuration.italic;
    property string config_placeholder: Plasmoid.configuration.placeholder;
    property string config_offset: Plasmoid.configuration.offset;
    property bool config_alignHorizontalLeft: Plasmoid.configuration.alignHorizontalLeft;
    property bool config_alignHorizontalCenter: Plasmoid.configuration.alignHorizontalCenter;
    property bool config_alignHorizontalRight: Plasmoid.configuration.alignHorizontalRight;
    property bool config_alignVerticalTop: Plasmoid.configuration.alignVerticalTop;
    property bool config_alignVerticalCenter: Plasmoid.configuration.alignVerticalCenter;
    property bool config_alignVerticalBottom: Plasmoid.configuration.alignVerticalBottom;

    // Variables
    property string previousTitle: "";
    property string previousArtist: "";
    property bool queryFailed: false;
    property bool fetchingLyrics: false;
    property bool lyricsFound: false;
    property string previousPlayerName: "";

    property string lrcQueryUrl: {
        // return `${lrclibBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}&album_name=${encodeURIComponent(album)}&q=${encodeURIComponent(title)}`; // Less accurate
        return `${lrclibBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}&album_name=${encodeURIComponent(album)}`; // Accurate
    }

    property int songTime: {
        if (position === 0) {
            return -1;
        } else {
            return (position / 1000000) - (config_offset / 1000);
        }
    }

    // List of current lyrics
    ListModel {
        id: lyricsList
    }

    // Texts

    Text {
        // TODO: word wrap
        id: lyricText
        color: config_color
        font.pixelSize: config_size
        font.bold: config_bold
        font.italic: config_italic
        anchors.margins: config_margin
        // anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        anchors.left: config_alignHorizontalLeft ? parent.left : undefined
        anchors.horizontalCenter: config_alignHorizontalCenter ? parent.horizontalCenter : undefined
        anchors.right: config_alignHorizontalRight ? parent.right : undefined
        anchors.top: config_alignVerticalTop ? parent.top : undefined
        anchors.verticalCenter: config_alignVerticalCenter ? parent.verticalCenter : undefined
        anchors.bottom: config_alignVerticalBottom ? parent.bottom : undefined
    }

    Timer {
        id: positionTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            mpris2Model.currentPlayer.updatePosition();
        }
    }

    // Timers

    Timer {
        id: schedulerTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (previousPlayerName !== playerName) {
                // console.log(`Player changed from ${previousPlayerName || "nothing"} to ${playerName || "nothing"}`);
                previousPlayerName = playerName;
                reset();
            }

            if (title !== previousTitle || artist !== previousArtist) {
                reset();
                previousTitle = title;
                previousArtist = artist;
                mainTimer.start();
            }
        }
    }
    
    Timer {
        id: mainTimer
        interval: 100
        running: false
        repeat: true
        onTriggered: {
            if (lyricsFound || queryFailed || fetchingLyrics) return;
            getLyrics();
        }
    }

    Timer {
        id: lyricDisplayTimer
        interval: 100
        running: false
        repeat: true
        onTriggered: {
            for (let i = 0; i < lyricsList.count; i++) {
                if (lyricsList.get(i).time >= songTime && songTime >= lyricsList.get(0).time) {
                    const lyricLine = lyricsList.get(Math.max(0, i - 1));
                    const lyric = lyricLine?.lyric;
                    lyricText.text = lyric || "";
                    break;
                }
            }
        }
    }

    // Functions

    // Parse lyrics
    function parseLyrics(lyrics) {
        const parsedLyrics = lyrics.split("\n");
        // console.log(`Got ${parsedLyrics.length} lines`);
        for (let i = 0; i < parsedLyrics.length; i++) {
            const lyricLine = parsedLyrics[i]; // [00:05.00] Lyric text
            const time = parseTime(lyricLine.match(/\[(.*)\]/)?.[1] || "");
            const lyric = lyricLine.match(/\[.*\] (.*)/)?.[1] || "";
            if (!time) continue; // Don't add if time is 0
            lyricsList.append({ time, lyric });
        }

        lyricDisplayTimer.start();
    }

    // Get lyrics
    function getLyrics() {
        fetchingLyrics = true;
        // console.log("Fetching lyrics...");
        const xhr = new XMLHttpRequest();
        xhr.open("GET", lrcQueryUrl);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Finished fetching
                fetchingLyrics = false;

                let responseJson;
                try {
                    responseJson = JSON.parse(xhr.responseText);
                } catch (err) { };
                const track = responseJson?.[0];

                if (xhr.status !== 200 || !track?.syncedLyrics) {
                    // console.log("Failed to get lyrics!");
                    queryFailed = true;
                    lyricsList.clear();
                    lyricText.text = config_placeholder;
                    return;
                }

                queryFailed = false;
                lyricsList.clear();
                // console.log("Fetched lyrics!");
                previousTitle = title;
                previousArtist = artist;
                lyricsFound = true;
                parseLyrics(track.syncedLyrics);
            }
        }

        xhr.send();
    }

    // Parse time
    function parseTime(timeString) {
        const parts = timeString.split(":");
        const minutes = parseInt(parts[0]);
        const seconds = parseFloat(parts[1]);
        return (minutes * 60) + seconds;
    }

    // Reset
    function reset() {
        mainTimer.stop();
        previousTitle = "";
        previousArtist = "";
        lyricsList.clear();
        queryFailed = false;
        lyricText.text = config_placeholder;
        lyricsFound = false;
    }
}
