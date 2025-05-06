//
//  Live.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 18/4/25.
//

import ComposableArchitecture
import MediaPlayerClient

extension MediaPlayerClient: DependencyKey {
    public static let liveValue: MediaPlayerClient = {
        let actor = MediaPlayerActor()
        
        return MediaPlayerClient(
            initialize: { view, playMode in
                try await actor.initialize(containerView: view, playMode: playMode)
            },
            setTrack: { url in
                try await actor.setTrack(url: url)
            },
            currentRate: {
                try await actor.currentRate()
            },
            setPlaybackRate : { rate in
                try await actor.setPlaybackRate(rate)
            },
            play: {
                try await actor.play()
            },
            pause: {
                try await actor.pause()
            },
            stop: {
                try await actor.stop()
            },
            seek: { time in
                try await actor.seek(to: time)
            },
            switchMode: { playMode in
                try await actor.switchMode(to: playMode)
            },
            currentTime: {
                AsyncStream { continuation in
                    Task { @MainActor in
                        for await value in actor.currentTimeStream() {
                            continuation.yield(value)
                        }
                        continuation.finish()
                    }
                }
            },
            duration: {
                try await actor.duration()
            },
            events: {
                AsyncStream { continuation in
                    Task { @MainActor in
                        for await value in actor.eventStream() {
                            continuation.yield(value)
                        }
                        continuation.finish()
                    }
                }
            },
			isEqualizerEnabled: {
				await actor.isEqualizerEnabled()
			},
            setEnableEqualizer: { enable in
                try await actor.setEnableEqualizer(enable)
            },
            setListEQ: { listEQ in
                try await actor.setListEQ(listEQ)
            },
            setEqualizer: { value, bandIndex in
                try await actor.setEqualizer(value, bandIndex)
            }
        )
    }()
}
