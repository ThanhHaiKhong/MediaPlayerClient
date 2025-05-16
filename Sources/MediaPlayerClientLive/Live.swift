//
//  Live.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 18/4/25.
//

import ComposableArchitecture
import MediaPlayerClient
import Foundation

extension MediaPlayerClient: DependencyKey {
    public static let liveValue: MediaPlayerClient = {
		let vlcActor = VLCActor()
		
        return MediaPlayerClient(
            initialize: { view, playMode in
				await vlcActor.initialize(containerView: view, playMode: playMode)
            },
            setTrack: { url in
				try await vlcActor.setTrack(url: url)
            },
            currentRate: {
                try await vlcActor.currentRate()
            },
            setPlaybackRate : { rate in
                try await vlcActor.setPlaybackRate(rate)
            },
            play: {
                try await vlcActor.play()
            },
            pause: {
                try await vlcActor.pause()
            },
            stop: {
                try await vlcActor.stop()
            },
            seek: { time in
                try await vlcActor.seek(to: time)
            },
            switchMode: { playMode in
                try await vlcActor.switchMode(to: playMode)
            },
            currentTime: {
				await vlcActor.currentTimeStream()
            },
            duration: {
				try await vlcActor.duration()
            },
            events: {
				await vlcActor.eventStream()
            },
			isEqualizerEnabled: {
				await vlcActor.isEqualizerEnabled()
			},
            setEnableEqualizer: { isEnabled, initialListEQ in
                try await vlcActor.setEnableEqualizer(isEnabled, initialListEQ)
            },
            setListEQ: { listEQ in
                try await vlcActor.setListEQ(listEQ)
            },
            setEqualizer: { value, bandIndex in
                try await vlcActor.setEqualizer(value, bandIndex)
            },
			setEqualizerWith: { preset in
				try await vlcActor.setEqualizerWith(preset)
			},
        )
    }()
}
