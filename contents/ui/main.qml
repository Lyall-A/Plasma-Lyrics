import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtQuick.Window 2.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
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

    // Constants
    readonly property string apiBaseUrl: "https://lrclib.net";

    // Configs
    property int config_width: Plasmoid.configuration.width;
    property int config_height: Plasmoid.configuration.height;
    property int config_size: Plasmoid.configuration.size;
    property int config_margin: Plasmoid.configuration.margin;
    property string config_color: Plasmoid.configuration.color;
    property bool config_bold: Plasmoid.configuration.bold;
    property bool config_italic: Plasmoid.configuration.italic;
    property int config_fade: Plasmoid.configuration.fade;
    property string config_noMedia: Plasmoid.configuration.noMedia;
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
    property int queryFailed: 0;
    property string previousPlayerName: "";
    property string newText: "";

    property string lyricQueryUrl: {
        if (queryFailed === 0) return `${apiBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist.replace(" - Topic", ""))}&album_name=${encodeURIComponent(album)}`; // Accurate
        if (queryFailed === 1) return `${apiBaseUrl}/api/search?q=${encodeURIComponent(title)}`; // Less accurate

        return "";
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

    // List of cached tracks
    ListModel {
        id: tracksList
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
        interval: 20
        running: true
        repeat: true
        onTriggered: {
            mpris2Model.currentPlayer?.updatePosition();
        }
    }

    Timer {
        id: mainTimer
        interval: 20
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
                
                // Blacklisted titles
                if ([
                    "Advertisement", // Spotify Ads
                    / \/ (X|Twitter)$/, // X/Twitter
                    /^TikTok - /, // TikTok
                ].some(match => (typeof match === "string" && match === title) || (match instanceof RegExp && match.test(title)))) return console.log(`Not getting lyrics for '${title}' (blacklisted title)!`);
                
                // Blacklisted artists
                if ([
                    "DJ X", // Spotify DJ
                    /^https:\/\/(x|twitter).com/, // X/Twitter
                    /^https:\/\/www.tiktok.com/, // TikTok
                ].some(match => (typeof match === "string" && match === artist) || (match instanceof RegExp && match.test(artist)))) return console.log(`Not getting lyrics for '${title}' (blacklisted artist)!`);
                
                getLyrics();
            }

            if (!isPlaying) setText(config_noMedia);
            if (isPlaying && !lyricsList.count && queryFailed > 0) setText(config_noLyrics);
        }
    }

    Timer {
        id: lyricDisplayTimer
        interval: 20
        running: false
        repeat: true
        onTriggered: {
            for (let i = 0; i < lyricsList.count; i++) {
                if (!isPlaying || lyricsList.get(i).time < songTime) continue;
                if (songTime >= lyricsList.get(0).time) {
                    const lyricLine = lyricsList.get(Math.max(0, i - 1));
                    const lyric = lyricLine?.lyric;
                    setText(lyric);
                    break;
                } else setText();
            }
        }
    }

    // Functions

    // Set text
    function setText(text = "") {
        if (newText === text) return;
        // console.log(`Setting text to '${text}'`);
        newText = text;
        if (!textTransition.running) textTransition.start(); else lyricText.text = text;
    }

    // Parse lyrics
    function parseLyrics(lyrics) {
        lyricsList.clear();
        const parsedLyrics = lyrics.split("\n");
        // console.log(`Got ${parsedLyrics.length} lines`);
        for (let i = 0; i < parsedLyrics.length; i++) {
            const lyricLine = parsedLyrics[i]; // [00:05.00] Lyric text
            const time = parseTime(lyricLine.match(/\[(.*)\]/)?.[1] || "");
            const lyric = lyricLine.match(/\[.*\] (.*)/)?.[1] || "";
            if (!time) continue; // Don't add if time is 0
            lyricsList.append({ time, lyric });
        }
        
        setText();
        lyricDisplayTimer.start();
    }

    // Get lyrics
    function getLyrics() {
        // Check for already existing track (cached)
        let foundTrack = false;
        for (let i = 0; i < tracksList.count; i++) {
            const track = tracksList.get(i);
            if (track.title === title && track.artist === artist && track.album === album) {
                foundTrack = true;
                console.log(`Got existing lyrics for '${title}'!`);
                parseLyrics(track.syncedLyrics);
            }
        }

        if (foundTrack) return;

        // Get using API
        if (!queryFailed) console.log(`Getting lyrics for '${title}'...`);

        const xhr = new XMLHttpRequest();
        xhr.open("GET", lyricQueryUrl);
        xhr.setRequestHeader("User-Agent", "Plasma-Lyrics (https://github.com/Lyall-A/Plasma-Lyrics)");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Finished fetching

                // Try parse JSON
                let responseJson;
                try {
                    responseJson = JSON.parse(xhr.responseText);
                } catch (err) { };
                const track = responseJson?.[0];
                const syncedLyrics = track?.syncedLyrics;

                if (xhr.status !== 200 || !syncedLyrics) {
                    // Failed (no synced lyrics)
                    if (!queryFailed) console.log(`Couldn't get lyrics for '${title}'`);
                    queryFailed++;

                    if (lyricQueryUrl && config_fallback) {
                        console.log(`Retrying with fallback search (x${queryFailed})...`);
                        getLyrics();
                    }
                    
                    if (!lyricQueryUrl && config_fallback) console.log(`Couldn't get lyrics for '${title}' with fallback search!`);

                    return;
                }

                // Got synced lyrics
                console.log(`Got lyrics for '${title}'!`);
                tracksList.append({ title, artist, album, syncedLyrics });
                parseLyrics(syncedLyrics);
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
        // console.log("Resetting");
        previousTitle = "";
        previousArtist = "";
        lyricsList.clear();
        queryFailed = 0;
        setText(config_noMedia);
    }
}
