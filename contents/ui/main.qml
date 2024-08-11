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
    property bool isPlaying: mpris2Model.currentPlayer?.playbackStatus === 2 ? true : false;

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
    property int config_fade: Plasmoid.configuration.fade;
    property string config_placeholder: Plasmoid.configuration.placeholder;
    property string config_noLyrics: Plasmoid.configuration.noLyrics;
    property int config_offset: Plasmoid.configuration.offset;
    property bool config_fallback: Plasmoid.configuration.fallback;
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
    property string newText: "";

    property string lrcQueryUrl: {
        return (queryFailed && config_fallback) ?
            `${lrclibBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist.replace(" - Topic", ""))}&album_name=${encodeURIComponent(album)}&q=${encodeURIComponent(title)}` : // Less accurate
            `${lrclibBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist.replace(" - Topic", ""))}&album_name=${encodeURIComponent(album)}`; // Accurate
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
        id: lyricText
        color: config_color
        wrapMode: Text.Wrap
        width: parent.width - (config_margin * 2)
        height: parent.height - (config_margin * 2)
        clip: true
        font.pixelSize: config_size
        font.bold: config_bold
        font.italic: config_italic
        anchors.margins: config_margin
        horizontalAlignment: config_alignHorizontalLeft ? Text.AlignLeft : config_alignHorizontalCenter ? Text.AlignHCenter : config_alignHorizontalRight ? Text.AlignRight : undefined
        verticalAlignment: config_alignVerticalTop ? Text.AlignTop : config_alignVerticalCenter ? Text.AlignVCenter : config_alignVerticalBottom ? Text.AlignBottom : undefined
        anchors.left: config_alignHorizontalLeft ? parent.left : undefined
        anchors.horizontalCenter: config_alignHorizontalCenter ? parent.horizontalCenter : undefined
        anchors.right: config_alignHorizontalCEnter ? parent.right : undefined
        anchors.top: config_alignVerticalTop ? parent.top : undefined
        anchors.verticalCenter: config_alignVerticalCenter ? parent.verticalCenter : undefined
        anchors.bottom: config_alignVerticalBottom ? parent.bottom : undefined
    }

    // Fade animation
    SequentialAnimation {
        id: textTransition
        running: false

        NumberAnimation {
            target: lyricText
            property: "opacity"
            to: 0
            duration: config_fade
        }

        ScriptAction {
            script: {
                lyricText.text = newText;
            }
        }

        NumberAnimation {
            target: lyricText
            property: "opacity"
            to: 1
            duration: config_fade
        }
    }

    // Timers

    Timer {
        id: positionTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            mpris2Model.currentPlayer?.updatePosition();
        }
    }

    Timer {
        id: schedulerTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            // Player change
            if (previousPlayerName !== playerName) {
                console.log(`Player changed from ${previousPlayerName || "nothing"} to ${playerName || "nothing"}`);
                previousPlayerName = playerName;
                reset();
            }

            // Track change
            if (title !== previousTitle || artist !== previousArtist) {
                reset();
                previousTitle = title;
                previousArtist = artist;
                if (title !== "Advertisement") mainTimer.start();
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
        interval: 20
        running: false
        repeat: true
        onTriggered: {
            for (let i = 0; i < lyricsList.count; i++) {
                if (lyricsList.get(i).time >= songTime && songTime >= lyricsList.get(0).time && isPlaying) {
                    const lyricLine = lyricsList.get(Math.max(0, i - 1));
                    const lyric = lyricLine?.lyric;
                    setText(lyric);
                    break;
                } else if (!isPlaying) setText();
            }
        }
    }

    // Functions

    // Set text
    function setText(text = "") {
        if (lyricText.text === text || newText === text) return;
        newText = text;
        if (!textTransition.running) textTransition.start(); else lyricText.text = text;
    }

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
        console.log(`Getting lyrics for '${title}'...`);
        fetchingLyrics = true;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", lrcQueryUrl);
        xhr.setRequestHeader("User-Agent", "Plasma-Lyrics (https://github.com/Lyall-A/Plasma-Lyrics)")
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
                    console.log(`Failed to get lyrics for '${title}'!`);
                    if (!queryFailed && config_fallback) {
                        console.log("Retrying with less accurate search...");
                        queryFailed = true;
                        return getLyrics();
                    }
                    queryFailed = true;
                    lyricsList.clear();
                    setText(config_noLyrics);
                    return;
                }

                queryFailed = false;
                lyricsList.clear();
                console.log(`Got lyrics for '${title}'!`);
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
        setText(config_placeholder);
        lyricsFound = false;
    }
}
