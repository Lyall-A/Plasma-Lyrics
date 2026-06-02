import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    Layout.preferredWidth: useFixedSize ? fixedWidth : implicitWidth
    Layout.preferredHeight: useFixedSize ? fixedHeight : implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight

    // Custom background
    Plasmoid.backgroundHints: useCustomBackground ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground
    Rectangle {
        visible: useCustomBackground
        color: backgroundColor
        radius: backgroundRadius
        anchors.fill: parent
    }

    Mpris.Mpris2Model {
        id: mpris2Model
    }

    // Constants
    readonly property string apiBaseUrl: Plasmoid.configuration.apiBaseUrl
    readonly property string apiUserAgent: 'Plasma-Lyrics (https://github.com/Lyall-A/Plasma-Lyrics)'
    readonly property string timerInterval: 1000 / 30 // 30 times a second
    readonly property bool debug: false
    readonly property var blacklist: ({
            title: ['Advertisement' // Spotify Ads
                , / \/ (X|Twitter)$/ // X/Twitter
                , /^TikTok - / // TikTok
                , 'A site is playing media', // Brave private window (maybe other chromium browsers as well?)
            ],
            album: [/^https:\/\/(x|twitter).com/ // X/Twitter
                , /^https:\/\/www.tiktok.com/, // TikTok
            ],
            artist: ['DJ X', // Spotify DJ
            ]
        })
    readonly property var replacement: ({
            title: [[/ \| YouTube Music$/, ''] // YouTube Music suffix
            ],
            album: [],
            artist: [[/ - Topic$/, ''] // YouTube Topic channels
            ]
        })

    // Player info
    readonly property string title: replacement.title.reduce((title, [pattern, value]) => title.replace(pattern, value), mpris2Model.currentPlayer?.track || '')
    readonly property string album: replacement.album.reduce((album, [pattern, value]) => album.replace(pattern, value), mpris2Model.currentPlayer?.album || '')
    readonly property string artist: {
        const artist = replacement.artist.reduce((artist, [pattern, value]) => artist.replace(pattern, value), mpris2Model.currentPlayer?.artist || '');
        return firstArtist ? artist.split(';')[0].trim() : artist;
    }
    readonly property string playerName: mpris2Model.currentPlayer?.objectName || ''
    readonly property int position: mpris2Model.currentPlayer?.position / 1000 || 0
    readonly property bool isPlaying: mpris2Model.currentPlayer?.playbackStatus === Mpris.PlaybackStatus.Playing ? true : false

    // Config
    readonly property bool useFixedSize: Plasmoid.configuration.useFixedSize
    readonly property int fixedWidth: Plasmoid.configuration.fixedWidth
    readonly property int fixedHeight: Plasmoid.configuration.fixedHeight
    readonly property int margin: Plasmoid.configuration.margin
    readonly property string fontFamily: Plasmoid.configuration.fontFamily
    readonly property int fontSize: Plasmoid.configuration.fontSize
    readonly property string fontColor: Plasmoid.configuration.fontColor
    readonly property bool fontBold: Plasmoid.configuration.fontBold
    readonly property bool fontItalic: Plasmoid.configuration.fontItalic
    readonly property bool useCustomBackground: Plasmoid.configuration.useCustomBackground
    readonly property string backgroundColor: Plasmoid.configuration.backgroundColor
    readonly property int backgroundRadius: Plasmoid.configuration.backgroundRadius
    readonly property int fade: Plasmoid.configuration.fade
    readonly property string noMedia: Plasmoid.configuration.noMedia
    readonly property string noLyrics: Plasmoid.configuration.noLyrics
    readonly property int offset: Plasmoid.configuration.offset
    readonly property bool allowSearch: Plasmoid.configuration.allowSearch
    readonly property bool firstArtist: Plasmoid.configuration.firstArtist
    readonly property bool horizontalAlignLeft: Plasmoid.configuration.horizontalAlignLeft
    readonly property bool horizontalAlignCenter: Plasmoid.configuration.horizontalAlignCenter
    readonly property bool horizontalAlignRight: Plasmoid.configuration.horizontalAlignRight
    readonly property bool verticalAlignTop: Plasmoid.configuration.verticalAlignTop
    readonly property bool verticalAlignCenter: Plasmoid.configuration.verticalAlignCenter
    readonly property bool verticalAlignBottom: Plasmoid.configuration.verticalAlignBottom

    // Variables
    property string previousTitle: ''
    property string previousArtist: ''
    property string previousPlayerName: ''
    property string currentLyricText: ''
    property int currentLyricIndex: 0
    property int failedAttempts: 0
    property string lyricsUrl: {
        if (failedAttempts === 0)
            return `${apiBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&album_name=${encodeURIComponent(album)}&artist_name=${encodeURIComponent(artist)}`;
        if (failedAttempts === 1)
            return `${apiBaseUrl}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
        if (failedAttempts === 2 && allowSearch)
            return `${apiBaseUrl}/api/search?q=${encodeURIComponent(title)}`;

        return '';
    }

    // Current lyrics
    ListModel {
        id: lyricsList
    }

    // Cached tracks
    ListModel {
        id: tracksList
    }

    Text {
        id: lyricText
        color: fontColor
        wrapMode: Text.Wrap
        horizontalAlignment: horizontalAlignLeft ? Text.AlignLeft : horizontalAlignCenter ? Text.AlignHCenter : horizontalAlignRight ? Text.AlignRight : undefined
        verticalAlignment: verticalAlignTop ? Text.AlignTop : verticalAlignCenter ? Text.AlignVCenter : verticalAlignBottom ? Text.AlignBottom : undefined
        font.pixelSize: fontSize
        font.bold: fontBold
        font.italic: fontItalic
        font.family: fontFamily
        anchors.margins: margin
        anchors.fill: parent
        anchors.left: horizontalAlignLeft ? parent.left : undefined
        anchors.horizontalCenter: horizontalAlignCenter ? parent.horizontalCenter : undefined
        anchors.right: horizontalAlignRight ? parent.right : undefined
        anchors.top: verticalAlignTop ? parent.top : undefined
        anchors.verticalCenter: verticalAlignCenter ? parent.verticalCenter : undefined
        anchors.bottom: verticalAlignBottom ? parent.bottom : undefined
    }

    // Fade animation
    SequentialAnimation {
        id: textTransition
        running: false

        NumberAnimation {
            target: lyricText
            property: 'opacity'
            to: 0
            duration: fade
        }

        ScriptAction {
            script: {
                lyricText.text = currentLyricText;
            }
        }

        NumberAnimation {
            target: lyricText
            property: 'opacity'
            to: 1
            duration: fade
        }
    }

    // Timers

    Timer {
        id: mainTimer
        interval: timerInterval
        running: true
        repeat: true
        onTriggered: {
            mpris2Model.currentPlayer?.updatePosition(); // Update MPRIS

            // Player changed (doesn't do anything)
            if (previousPlayerName !== playerName) {
                console.log(`Player changed from ${previousPlayerName || 'nothing'} to ${playerName || 'nothing'}`);
                previousPlayerName = playerName;
            }

            // Track changed
            if (title !== previousTitle || artist !== previousArtist) {
                previousTitle = title;
                previousArtist = artist;
                failedAttempts = 0;
                lyricsList.clear();

                if (!title)
                    return;

                // Blacklisted
                if (matchString(blacklist.title, title))
                    return console.log(`Not getting lyrics for '${title}' (blacklisted title)`);
                if (matchString(blacklist.album, album))
                    return console.log(`Not getting lyrics for '${title}' (blacklisted album)`);
                if (matchString(blacklist.artist, artist))
                    return console.log(`Not getting lyrics for '${title}' (blacklisted artist)`);

                updateLyrics();
            }

            if (!isPlaying) {
                // No media playing
                setText(noMedia);
            } else if (!lyricsUrl) {
                // Media playing, but no lyricsUrl (meaning all attempts at fetching lyrics failed)
                setText(noLyrics);
            } else if (lyricsList.count === 0) {
                // Media playing, no lyrics, but also no error
                setText();
            } else {
                // Media playing and lyrics available
                for (let lyricIndex = lyricsList.count - 1; lyricIndex >= 0; lyricIndex--) {
                    const {
                        time,
                        lyric
                    } = lyricsList.get(lyricIndex);
                    if ((position - offset) >= time) {
                        setText(lyric, currentLyricIndex !== lyricIndex);
                        currentLyricIndex = lyricIndex;
                        break;
                    } else if (lyricIndex === 0)
                        setText(); // Too early
                }
            }
        }
    }

    // Functions

    function setText(text = '', repeatTransition = false) {
        if (currentLyricText === text && !repeatTransition)
            return;
        logDebug(`Setting text to '${text}'`);
        currentLyricText = text;
        if (!textTransition.running)
            textTransition.start();
        else
            lyricText.text = text;
    }

    function matchString(array, value) {
        return array.some(match => (typeof match === 'string' && match === value) || // String matches
            (match instanceof RegExp && match.test(value)) // Regex matches
        );
    }

    function useLyrics(lyrics) {
        // lyricsList.clear();
        const parsedLyrics = lyrics.split('\n');
        logDebug(`Got ${parsedLyrics.length} lines`);
        for (const line of parsedLyrics) {
            const time = parseTime(line.match(/\[(.*)\]/)?.[1] || '');
            const lyric = line.match(/\[.*\]\s*(.*)/)?.[1] || '';
            // if (!time) continue; // Don't add if time is 0
            lyricsList.append({
                time,
                lyric
            });
        }

        // setText();
    }

    function updateLyrics() {
        // Check for cached track
        const cachedTrack = failedAttempts === 0 ? new Array(tracksList.count).fill().map(i => tracksList.get(i)).find(track => track.title === title && track.album === album && track.artist === artist) : undefined;

        if (cachedTrack) {
            console.log(`Got cached lyrics for '${title}'`);
            return useLyrics(cachedTrack.lyrics);
        }

        const url = lyricsUrl;

        if (!url)
            return console.log(`Failed to get lyrics after ${failedAttempts} attempt(s)!`);

        console.log(`Getting lyrics for '${title}' (attempt ${failedAttempts + 1})`);
        logDebug(`Fetching '${url}'`);

        const xhr = new XMLHttpRequest();
        xhr.open('GET', url);
        xhr.setRequestHeader('User-Agent', apiUserAgent);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (url !== lyricsUrl)
                    return console.log('URL changed mid-request, ignoring');

                // Try parse JSON
                let responseJson;
                try {
                    responseJson = JSON.parse(xhr.responseText);
                } catch (err) {}

                const track = responseJson?.find(track => track?.syncedLyrics); // Get first track that has synced lyrics
                const lyrics = track?.syncedLyrics;

                if (!lyrics) {
                    failedAttempts++;
                    return updateLyrics();
                }

                // Got synced lyrics
                console.log(`Got lyrics for '${title}'`);
                failedAttempts = 0;
                tracksList.append({
                    title,
                    album,
                    artist,
                    lyrics
                }); // Add to cache
                logDebug(`Cached tracks: ${tracksList.count}`);
                useLyrics(lyrics);
            }
        };
        xhr.send();
    }

    function parseTime(timeString) {
        const parts = timeString.split(':');
        const minutes = parseInt(parts[0]);
        const seconds = parseFloat(parts[1]);
        return (minutes * 60 * 1000) + (seconds * 1000);
    }

    function logDebug(...msg) {
        if (!debug)
            return false;
        return console.log('[DEBUG]', ...msg);
    }
}
