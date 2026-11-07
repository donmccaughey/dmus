import Foundation
import Testing

@MainActor
struct PlayerTests {
    let first = Track(trackName: "First", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/First.mp3")
    let second = Track(trackName: "Second", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Second.mp3")
    let third = Track(trackName: "Third", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Third.m4a")

    let audio = AudioFake()

    func makePlayer(_ tracks: [Track] = []) -> Player {
        let player = Player(audio: audio)
        for track in tracks {
            player.queue.add(track)
        }
        return player
    }

    func makePlayingPlayer(_ tracks: [Track]) -> Player {
        let player = makePlayer(tracks)
        player.play()
        audio.clearCalls()
        return player
    }

    @Test func newPlayerIsStoppedWithEmptyQueue() {
        let player = makePlayer()
        #expect(player.queue.isEmpty)
        #expect(player.currentTrack == nil)
        #expect(player.nextTrack == nil)
        #expect(player.timeIndex == 0)
        #expect(!player.isPlaying)
    }

    @Test func currentAndNextTrackComeFromTheHeadOfTheQueue() {
        #expect(makePlayer([first]).currentTrack == first)
        #expect(makePlayer([first]).nextTrack == nil)
        #expect(makePlayer([first, second]).nextTrack == second)
        #expect(makePlayer([first, second, third]).nextTrack == second)
    }

    @Test func commandsAreIgnoredWhileQueueIsEmpty() {
        let player = makePlayer()
        player.play()
        player.stop()
        player.back()
        player.next()
        player.clear()
        #expect(audio.calls.isEmpty)
        #expect(player.timeIndex == 0)
        #expect(!player.isPlaying)
    }

    @Test func playStartsCurrentTrackAtTimeIndexWithNextTrack() {
        let player = makePlayer([first, second, third])
        player.play()
        #expect(audio.calls == [.play(first.url, from: 0, thenPlay: second.url)])
        #expect(player.isPlaying)
    }

    @Test func playIsIgnoredWhileInPlayback() {
        let player = makePlayingPlayer([first])
        player.play()
        #expect(audio.calls.isEmpty)
        #expect(player.isPlaying)
    }

    @Test func stopRecordsPositionAndStopsAudio() {
        let player = makePlayingPlayer([first])
        audio.playbackPosition = 12.5
        player.stop()
        #expect(audio.calls == [.stop])
        #expect(player.timeIndex == 12.5)
        #expect(!player.isPlaying)
    }

    @Test func stopIsIgnoredWhileStopped() {
        let player = makePlayer([first])
        player.stop()
        #expect(audio.calls.isEmpty)
    }

    @Test func playAfterStopResumesAtRecordedTimeIndex() {
        let player = makePlayingPlayer([first, second])
        audio.playbackPosition = 30
        player.stop()
        audio.clearCalls()
        player.play()
        #expect(audio.calls == [.play(first.url, from: 30, thenPlay: second.url)])
    }

    @Test func backWhileStoppedResetsTimeIndex() {
        let player = makePlayingPlayer([first])
        audio.playbackPosition = 5
        player.stop()
        audio.clearCalls()
        player.back()
        #expect(player.timeIndex == 0)
        #expect(audio.calls.isEmpty)
        #expect(player.currentTrack == first)
    }

    @Test func backWhileInPlaybackRestartsCurrentTrack() {
        let player = makePlayingPlayer([first, second])
        audio.reportPosition(5)
        player.back()
        #expect(player.timeIndex == 0)
        #expect(audio.calls == [.play(first.url, from: 0, thenPlay: second.url)])
        #expect(player.isPlaying)
    }

    @Test func nextWhileStoppedDiscardsCurrentTrack() {
        let player = makePlayingPlayer([first, second])
        audio.playbackPosition = 5
        player.stop()
        audio.clearCalls()
        player.next()
        #expect(player.timeIndex == 0)
        #expect(player.queue.tracks == [second])
        #expect(audio.calls.isEmpty)
        #expect(!player.isPlaying)
    }

    @Test func nextWhileInPlaybackWithNextTrackPlaysIt() {
        let player = makePlayingPlayer([first, second, third])
        player.next()
        #expect(player.queue.tracks == [second, third])
        #expect(player.timeIndex == 0)
        #expect(audio.calls == [.play(second.url, from: 0, thenPlay: third.url)])
        #expect(player.isPlaying)
    }

    @Test func nextWhileInPlaybackWithoutNextTrackStops() {
        let player = makePlayingPlayer([first])
        player.next()
        #expect(player.queue.isEmpty)
        #expect(player.timeIndex == 0)
        #expect(audio.calls == [.stop])
        #expect(!player.isPlaying)
    }

    @Test func clearWhileStoppedEmptiesQueue() {
        let player = makePlayingPlayer([first, second])
        audio.playbackPosition = 5
        player.stop()
        audio.clearCalls()
        player.clear()
        #expect(player.queue.isEmpty)
        #expect(player.timeIndex == 0)
        #expect(audio.calls.isEmpty)
    }

    @Test func clearWhileInPlaybackStops() {
        let player = makePlayingPlayer([first, second])
        player.clear()
        #expect(player.queue.isEmpty)
        #expect(player.timeIndex == 0)
        #expect(audio.calls == [.stop])
        #expect(!player.isPlaying)
    }

    @Test func finishedTrackIsRemovedAndNextTrackIsQueuedForAudio() {
        let player = makePlayingPlayer([first, second, third])
        audio.reportPosition(180)
        audio.finishCurrentTrack()
        #expect(player.queue.tracks == [second, third])
        #expect(player.currentTrack == second)
        #expect(player.timeIndex == 0)
        #expect(audio.calls == [.replaceNextTrack(third.url)])
        #expect(player.isPlaying)
    }

    @Test func finishedLastTrackEmptiesQueueAndStops() {
        let player = makePlayingPlayer([first])
        audio.finishCurrentTrack()
        #expect(player.queue.isEmpty)
        #expect(player.timeIndex == 0)
        #expect(!player.isPlaying)
        #expect(audio.calls.isEmpty)
    }

    @Test func positionReportsUpdateTimeIndexWhileInPlayback() {
        let player = makePlayingPlayer([first])
        audio.reportPosition(42.25)
        #expect(player.timeIndex == 42.25)
    }

    @Test func positionReportsAreIgnoredWhileStopped() {
        let player = makePlayer([first])
        audio.reportPosition(42.25)
        #expect(player.timeIndex == 0)
    }

    @Test func trackAddedDuringPlaybackBecomesAudioNextTrack() {
        let player = makePlayingPlayer([first])
        player.queue.add(second)
        #expect(audio.calls == [.replaceNextTrack(second.url)])
        player.queue.add(third)
        #expect(audio.calls == [.replaceNextTrack(second.url), .replaceNextTrack(second.url)])
    }

    @Test func trackAddedWhileStoppedDoesNotTouchAudio() {
        let player = makePlayer([first])
        player.queue.add(second)
        #expect(audio.calls.isEmpty)
    }

    @Test func playingAndStoppingEachPostDidChange() {
        let player = makePlayer([first])
        let changes = NotificationCounter(name: Player.didChangeNotification, object: player)
        player.play()
        #expect(changes.count == 1)
        player.stop()
        #expect(changes.count == 2)
    }

    @Test func positionReportsDoNotPostDidChange() {
        let player = makePlayingPlayer([first])
        let changes = NotificationCounter(name: Player.didChangeNotification, object: player)
        audio.reportPosition(42.25)
        #expect(player.timeIndex == 42.25)
        #expect(changes.count == 0)
    }

    @Test func finishedLastTrackPostsDidChange() {
        let player = makePlayingPlayer([first])
        let changes = NotificationCounter(name: Player.didChangeNotification, object: player)
        audio.finishCurrentTrack()
        #expect(!player.isPlaying)
        #expect(changes.count == 1)
    }
}
