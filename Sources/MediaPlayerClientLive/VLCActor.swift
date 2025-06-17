//
//  VLCActor.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 13/5/25.
//

import MediaPlayerClient
import MobileVLCKit

actor VLCActor: Sendable {
	private let player: VLCPlayer
	
	init() {
		self.player = VLCPlayer()
	}
	
	func initialize(containerView: UIView, playMode: MediaPlayerClient.PlayMode?) async {
		await player.initialize(containerView: containerView, playMode: playMode)
	}
	
	func setTrack(url: URL) async throws {
		try await player.setTrack(url: url)
	}
	
	func play() async throws {
		try await player.play()
	}
	
	func pause() async throws {
		try await player.pause()
	}
	
	func stop() async throws {
		try await player.stop()
	}
	
	func seek(to time: TimeInterval) async throws {
		try await player.seek(to: time)
	}
	
	func currentRate() async throws -> Float {
		try await player.currentRate()
	}
	
	func setPlaybackRate(_ rate: Float) async throws {
		try await player.setPlaybackRate(rate)
	}
	
	func duration() async throws -> TimeInterval {
		try await player.duration()
	}
	
	func currentTimeStream() -> AsyncStream<MediaPlayerClient.TimeRecord> {
		player.currentTimeStream()
	}
	
	func eventStream() -> AsyncStream<MediaPlayerClient.PlaybackEvent> {
		player.eventStream()
	}
	
	func switchMode(to playMode: MediaPlayerClient.PlayMode) async throws {
		
	}
	
	func isEqualizerEnabled() async -> Bool {
		await player.isEqualizerEnabled()
	}
	
	func setEnableEqualizer(_ isEnabled: Bool, _ initialListEQ: [Float]) async throws {
		try await player.setEnableEqualizer(isEnabled, initialListEQ)
	}
	
	func setListEQ(_ listEQ: [Float]) async throws {
		try await player.setListEQ(listEQ)
	}
	
	func setEqualizer(_ value: Float, _ bandIndex: Int) async throws {
		try await player.setEqualizer(value, bandIndex: bandIndex)
	}
	
	func setEqualizerWith(_ preset: MediaPlayerClient.AudioEqualizer.Preset) async throws {
		try await player.setEqualizer(preset)
	}
	
	func currentListEQ() async -> [Float] {
		await player.currentListEQ()
	}
	
	func isPlaying() async -> Bool {
		await player.isPlaying()
	}
}

final private class VLCPlayer: NSObject, @unchecked Sendable {
	
	private let player = VLCMediaPlayer()
	private var containerView: UIView?
	private var playMode: MediaPlayerClient.PlayMode = .video
	private var isEnabledEqualizer: Bool = false
	private var hasNotifiedDuration = false
	private let audioEqualizer = VLCAudioEqualizer()
	private var lastUpdateTime: TimeInterval = .zero
	private var listEQ: [Float] = Array(repeating: 0.0, count: 10)
	
	private var eventContinuation: AsyncStream<MediaPlayerClient.PlaybackEvent>.Continuation?
	private var timeContinuation: AsyncStream<MediaPlayerClient.TimeRecord>.Continuation?
	
	deinit {
		player.stop()
		player.media = nil
		player.media?.delegate = nil
		player.drawable = nil
		player.delegate = nil
	}
	
	@MainActor
	func initialize(containerView: UIView, playMode: MediaPlayerClient.PlayMode?) async {
		self.containerView = containerView
		if let playMode {
			self.playMode = playMode
		}
		
		player.drawable = containerView
		player.delegate = self
		player.equalizer = audioEqualizer
	}
	
	func setTrack(url: URL) async throws {
		player.stop()
		let media = VLCMedia(url: url)
		media.addOptions([
			"network-caching": 1500, 	// cache 1500ms (1.5 giây) trong RAM
			"file-caching": 2000,    	// cache 2 giây cho file local
			"live-caching": 3000,    	// cache 3 giây cho stream live
			"tcp-caching": 1500,     	// TCP stream
			"rtsp-caching": 3000, 		// RTSP stream
			"http-reconnect": true,  	// tự động kết nối lại nếu mất kết nối
		])
		player.media = media
		hasNotifiedDuration = false
		player.play()
		lastUpdateTime = .zero
	}
	
	func play() async throws {
		player.play()
		lastUpdateTime = .zero
	}
	
	func pause() async throws {
		if player.canPause {
			player.pause()
			lastUpdateTime = .zero
		}
	}
	
	func stop() async throws {
		player.stop()
		lastUpdateTime = .zero
	}
	
	func seek(to time: TimeInterval) async throws {
		if player.isSeekable {
			player.time = VLCTime(int: Int32(time * 1000))
			lastUpdateTime = .zero
		}
	}
	
	func currentRate() async throws -> Float {
		player.rate
	}
	
	func setPlaybackRate(_ rate: Float) async throws {
		player.rate = rate
	}
	
	func duration() async throws -> TimeInterval {
		if let media = player.media {
			return TimeInterval(media.length.intValue / 1000)
		}
		return 0.0
	}
	
	func currentTimeStream() -> AsyncStream<MediaPlayerClient.TimeRecord> {
		AsyncStream { continuation in
			self.timeContinuation = continuation
			continuation.onTermination = { [weak self] _ in
				Task { @MainActor in
					self?.timeContinuation = nil
				}
			}
		}
	}
	
	func eventStream() -> AsyncStream<MediaPlayerClient.PlaybackEvent> {
		AsyncStream { continuation in
			self.eventContinuation = continuation
			continuation.onTermination = { [weak self] _ in
				Task { @MainActor in
					self?.eventContinuation = nil
				}
			}
		}
	}
	
	func isEqualizerEnabled() async -> Bool {
		isEnabledEqualizer
	}
	
	func setEnableEqualizer(_ isEnabled: Bool, _ initialListEQ: [Float] = []) async throws {
		isEnabledEqualizer = isEnabled
		var listEQ: [Float] = Array(repeating: 0.0, count: 10)
		
		if isEnabled {
			if initialListEQ.isEmpty {
				listEQ = initialListEQ
			}
		}
		
		let bandCount = audioEqualizer.bands.count
		guard listEQ.count <= bandCount else {
			throw MediaPlayerClient.PlayerError.invalidEqualizerBandCount
		}
		
		for (index, value) in listEQ.enumerated() {
			audioEqualizer.bands[index].amplification = value
		}
	}
	
	func setListEQ(_ listEQ: [Float]) async throws {
		self.listEQ = listEQ
		
		guard isEnabledEqualizer else {
			throw MediaPlayerClient.PlayerError.equalizerNotEnabled
		}
		
		let bandCount = audioEqualizer.bands.count
		guard listEQ.count <= bandCount else {
			throw MediaPlayerClient.PlayerError.invalidEqualizerBandCount
		}
		
		for (index, value) in listEQ.enumerated() {
			audioEqualizer.bands[index].amplification = value
		}
	}
	
	func setEqualizer(_ value: Float, bandIndex: Int) async throws {
		guard isEnabledEqualizer else {
			throw MediaPlayerClient.PlayerError.equalizerNotEnabled
		}
		guard bandIndex >= 0 && bandIndex < audioEqualizer.bands.count else {
			throw MediaPlayerClient.PlayerError.invalidEqualizerBandIndex
		}
		audioEqualizer.bands[bandIndex].amplification = value
		if listEQ.count > bandIndex {
			listEQ[bandIndex] = value
		}
	}
	
	func setEqualizer(_ preset: MediaPlayerClient.AudioEqualizer.Preset) async throws {
		guard isEnabledEqualizer else {
			throw MediaPlayerClient.PlayerError.equalizerNotEnabled
		}
		
		let mediaEqualizer = preset.toEqualizer()
		audioEqualizer.preAmplification = mediaEqualizer.preAmplification
		
		for band in audioEqualizer.bands {
			band.amplification = mediaEqualizer.bands[Int(band.index)].amplification
		}
		
		self.listEQ = mediaEqualizer.bands.map { $0.amplification }
	}
	
	func currentListEQ() async -> [Float] {
		listEQ
	}
	
	func isPlaying() async -> Bool {
		player.isPlaying
	}
}

extension VLCPlayer: VLCMediaPlayerDelegate {
	
	func mediaPlayerStateChanged(_ aNotification: Notification) {
		guard let player = aNotification.object as? VLCMediaPlayer else { return }
		
		switch player.state {
		case .playing:
			eventContinuation?.yield(.didStartPlaying)
			
		case .paused:
			eventContinuation?.yield(.didPause)
			
		case .stopped:
			eventContinuation?.yield(.didStop)
			
		case .buffering:
			eventContinuation?.yield(.buffering(true))
			
		case .ended:
			eventContinuation?.yield(.didToEnd)
			
		case .error:
			eventContinuation?.yield(.error(MediaPlayerClient.PlayerError.playbackFailed))
			
		default:
			break
		}
	}
	
	func mediaPlayerTimeChanged(_ aNotification: Notification) {
		guard let player = aNotification.object as? VLCMediaPlayer, let media = player.media else { return }
		
		let currentTime = TimeInterval(player.time.intValue / 1000)
		let duration = TimeInterval(media.length.intValue / 1000)
		let now = Date().timeIntervalSince1970
		
		if !hasNotifiedDuration, duration > 0 {
			eventContinuation?.yield(.readyToPlay)
			hasNotifiedDuration = true
		}
		
		if now - lastUpdateTime >= 1.0 {
			lastUpdateTime = now
			let timeRecord = MediaPlayerClient.TimeRecord(currentTime: currentTime, duration: duration)
			timeContinuation?.yield(timeRecord)
		}
	}
}

extension MediaPlayerClient.AudioEqualizer.Preset {
	
	func toVLCPreset() -> VLCAudioEqualizer.Preset? {
		let index = self.index
		guard let preset = VLCAudioEqualizer.presets.first(where: { $0.index == index }) else {
			return nil
		}
		return preset
	}
}
