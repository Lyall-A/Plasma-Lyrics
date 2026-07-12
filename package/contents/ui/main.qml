import QtQuick
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
    readonly property string defaultUserAgent: 'Plasma-Lyrics (https://github.com/Lyall-A/Plasma-Lyrics)'
    readonly property string timerInterval: 1000 / 30 // 30 times a second
    readonly property bool debug: true
    readonly property var blacklist: ({
        title: [
            'Advertisement', // Spotify Ads
            / \/ (X|Twitter)$/, // X/Twitter
            /^TikTok - /, // TikTok
            'A site is playing media', // Brave private window (maybe other chromium browsers as well?)
        ],
        album: [
            /^https:\/\/(x|twitter).com/, // X/Twitter
            /^https:\/\/www.tiktok.com/, // TikTok
        ],
        artist: [
            'DJ X', // Spotify DJ
        ]
    })
    readonly property var replacement: ({
        title: [
            [/ \| YouTube Music$/, ''] // YouTube Music suffix
        ],
        album: [],
        artist: [
            [/ - Topic$/, ''] // YouTube Topic channels
        ]
    })
    readonly property var providers: ([
        {
            name: 'LRCLIB',
            baseUrl: Plasmoid.configuration.baseUrlLrcLib,
            useJson: true,
            requestHandler: (attempt) => {
                if (attempt === 0) return { url: `${baseUrlLrcLib}/api/search?track_name=${encodeURIComponent(title)}&album_name=${encodeURIComponent(album)}&artist_name=${encodeURIComponent(artist)}` };
                if (attempt === 1) return { url: `${baseUrlLrcLib}/api/search?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}` };
                if (attempt === 2 && allowSearch) return { url: `${baseUrlLrcLib}/api/search?q=${encodeURIComponent(title)}` };
            },
            parser: (res) => {
                const track = res?.find(track => track?.syncedLyrics); // Get first track that has synced lyrics
                const lyrics = track?.syncedLyrics;
                return lyrics ?? null;
            }
        },
        {
            name: 'LrcApi',
            baseUrl: Plasmoid.configuration.baseUrlLrcLib,
            useJson: false,
            requestHandler: (attempt) => {
                if (attempt === 0) return { url: `${baseUrlLrcApi}/lyrics?title=${encodeURIComponent(title)}&artist=${encodeURIComponent(artist)}` };
            },
            parser: (res, attempt) => {
                return res;
            }
        }
    ])

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
    readonly property string baseUrlLrcLib: Plasmoid.configuration.baseUrlLrcLib
    readonly property string baseUrlLrcApi: Plasmoid.configuration.baseUrlLrcApi
    readonly property string providerPriorities: Plasmoid.configuration.providerPriorities

    // Variables
    property string previousTitle: ''
    property string previousArtist: ''
    property string previousPlayerName: ''
    property string currentLyricText: ''
    property string currentProvider: ''
    property bool gettingLyrics: false
    property double lastRequestDate: 0
    property int currentLyricIndex: 0
    property int currentAttempt: 0

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
        horizontalAlignment:
            horizontalAlignLeft ? Text.AlignLeft :
            horizontalAlignCenter ? Text.AlignHCenter :
            horizontalAlignRight ? Text.AlignRight :
            undefined
        verticalAlignment:
            verticalAlignTop ? Text.AlignTop :
            verticalAlignCenter ? Text.AlignVCenter :
            verticalAlignBottom ? Text.AlignBottom :
            undefined
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
                currentAttempt = 0;
                currentProvider = 0
                lyricsList.clear();

                if (!title) return;

                // Blacklisted
                if (matchString(blacklist.title, title)) return console.log(`Not getting lyrics for '${title}' (blacklisted title)`);
                if (matchString(blacklist.album, album)) return console.log(`Not getting lyrics for '${title}' (blacklisted album)`);
                if (matchString(blacklist.artist, artist)) return console.log(`Not getting lyrics for '${title}' (blacklisted artist)`);

                updateLyrics();
            }

            if (!isPlaying) {
                // No media playing
                setText(noMedia);
            } else if (gettingLyrics) {
                // Media playing, still getting lyrics
                setText();
            } else if (!gettingLyrics && lyricsList.count === 0) {
                // Media playing, but no lyrics found
                setText(noLyrics);
            } else {
                // Media playing, lyrics available
                for (let lyricIndex = lyricsList.count - 1; lyricIndex >= 0; lyricIndex--) {
                    const { time, lyric } = lyricsList.get(lyricIndex);
                    if ((position - offset) >= time) {
                        setText(lyric, currentLyricIndex !== lyricIndex);
                        currentLyricIndex = lyricIndex;
                        break;
                    } else if (lyricIndex === 0) setText(); // Too early
                }
            }
        }
    }

    // Functions

    function setText(text = '', repeatTransition = false) {
        if (currentLyricText === text && !repeatTransition) return;
        logDebug(`Setting text to '${text}'`);
        currentLyricText = text;
        if (!textTransition.running) textTransition.start(); else lyricText.text = text;
    }

    function matchString(array, value) {
        return array.some(match =>
            (typeof match === 'string' && match === value) || // String matches
            (match instanceof RegExp && match.test(value)) // Regex matches
        );
    }

    function useLyrics(lyrics) {
        const parsedLyrics = lyrics.split('\n');
        logDebug(`Got ${parsedLyrics.length} lines`);
        for (const line of parsedLyrics) {
            const time = parseTime(line.match(/\[(.*)\]/)?.[1] || '');
            const lyric = line.match(/\[.*\]\s*(.*)/)?.[1] || '';
            // if (!time) continue; // Don't add if time is 0 (could be metadata)
            if (isNaN(time)) continue;
            lyricsList.append({ time, lyric });
        }
    }

    function updateLyrics() {
        gettingLyrics = true;

        if (currentAttempt === 0) {
            // Check for cached track
            const cachedTrack = new Array(tracksList.count)
                .fill()
                .map(i => tracksList.get(i))
                .find(track =>
                    track.title === title &&
                    track.album === album &&
                    track.artist === artist
                );

            if (cachedTrack) {
                gettingLyrics = false;
                console.log(`Got cached lyrics for '${title}'`);
                return useLyrics(cachedTrack.lyrics);
            }
        }

        const provider = providers.find(provider => provider.name === providerPriorities.split(',')[currentProvider]);
        const requestOptions = provider.requestHandler(currentAttempt);

        if (!requestOptions) {
            if (providerPriorities.split(',')[++currentProvider]) {
                currentAttempt = 0;
                return updateLyrics();
            } else {
                gettingLyrics = false;
                currentAttempt = 0;
                return console.log(`Failed to get lyrics after ${currentAttempt} attempt(s)!`);
            }
        }

        console.log(`Getting lyrics for '${title}' using ${provider.name} (attempt ${currentAttempt + 1})`);
        logDebug(`Fetching '${requestOptions.url}'`);

        const requestDate = Date.now();
        lastRequestDate = requestDate;

        const xhr = new XMLHttpRequest();
        xhr.open(requestOptions.method ?? 'GET', requestOptions.url);
        xhr.setRequestHeader('User-Agent', provider.userAgent || defaultUserAgent);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log(requestDate, lastRequestDate)
                if (requestDate !== lastRequestDate) return logDebug('Request is no longer relevant');

                const { responseText } = xhr;
                let responseJson;

                if (provider.useJson) {
                    // Try parse JSON
                    try {
                        responseJson = JSON.parse(xhr.responseText);
                    } catch (err) { };
                }

                const lyrics = provider.parser(responseJson ?? responseText);

                if (!lyrics) {
                    currentAttempt++;
                    return updateLyrics();
                }


                // Got synced lyrics
                console.log(`Got lyrics for '${title}'`);
                gettingLyrics = false;
                currentAttempt = 0;
                tracksList.append({ title, album, artist, lyrics }); // Add to cache
                logDebug(`Cached tracks: ${tracksList.count}`);
                useLyrics(lyrics);
            }
        }
        xhr.send();
    }

    function parseTime(timeString) {
        const parts = timeString.split(':');
        const minutes = parseInt(parts[0]);
        const seconds = parseFloat(parts[1]);
        return (minutes * 60 * 1000) + (seconds * 1000);
    }

    function logDebug(...msg) {
        if (!debug) return false;
        return console.log('[DEBUG]', ...msg);
    }
}