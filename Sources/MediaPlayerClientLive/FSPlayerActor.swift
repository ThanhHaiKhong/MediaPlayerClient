//
//  FSPlayerActor.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 9/5/25.
//
/*
import MediaPlayerClient
import FSPlayer

@MainActor
final internal class FSPlayerActor: Sendable {
	
	private var player: FSPlayer?
	private var containerView: UIView?
	private var playMode: MediaPlayerClient.PlayMode = .video
	private var currentURL: URL?
	private var timeTask: Task<Void, Never>?
	
	private var eventContinuation: AsyncStream<MediaPlayerClient.PlaybackEvent>.Continuation?
	private var timeContinuation: AsyncStream<MediaPlayerClient.TimeRecord>.Continuation?
	
	public init() {
		setupObservers()
	}
	
	private lazy var options: FSOptions = {
		let options = FSOptions.byDefault()
		options.setPlayerOptionIntValue(3840, forKey: "videotoolbox-max-frame-width")
		options.setPlayerOptionIntValue(1, forKey: "videotoolbox_hwaccel")
		options.metalRenderer = true
		return options
	}()
	
	func initialize(containerView: UIView, playMode: MediaPlayerClient.PlayMode?) async {
		self.containerView = containerView
		if let playMode {
			self.playMode = playMode
		}
	}
	
	func setTrack(url: URL) async throws  {
		self.currentURL = url
		
		let wasPlaying = player?.isPlaying() ?? true
		player?.stop()
		player = FSPlayer(contentURL: url, with: options)
		player?.setPauseInBackground(false)
		
		guard let player = player, let playerView = player.view, let containerView = containerView else {
			throw MediaPlayerClient.PlayerError.notInitialized
		}
		
		playerView.frame = containerView.bounds
		
		if containerView.subviews.count > 0 {
			containerView.subviews[0].removeFromSuperview()
		}
		
		containerView.addSubview(playerView)
		
		player.scalingMode = .aspectFit
		player.shouldAutoplay = wasPlaying
		player.prepareToPlay()
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
	
	func currentRate() async throws -> Float {
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		return player.playbackRate
	}
	
	func setPlaybackRate(_ rate: Float) async throws {
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		player.playbackRate = rate
	}
	
	func duration() async throws -> TimeInterval {
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		return player.duration
	}
	
	func play() async throws {
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		player.play()
	}
	
	func pause() async throws {
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		player.pause()
	}
	
	func stop() async throws {
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		player.stop()
		self.player = nil
	}
	
	func seek(to time: TimeInterval) async throws {
		/*
		guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
		return try await withCheckedThrowingContinuation { continuation in
			player.seek(toTime: time) { success in
				if success {
					continuation.resume()
				} else {
					continuation.resume(throwing: MediaPlayerClient.PlayerError.seekFailed)
				}
			}
		}
		*/
	}
}

extension FSPlayerActor {
	
	private func setupObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(playerPreparedToPlay(_:)), name: Notification.Name.FSPlayerIsPreparedToPlay, object: player)
		NotificationCenter.default.addObserver(self, selector: #selector(loadStateDidChange(_:)), name: Notification.Name.FSPlayerLoadStateDidChange, object: player)
		NotificationCenter.default.addObserver(self, selector: #selector(playbackStateDidChange(_:)), name: Notification.Name.FSPlayerPlaybackStateDidChange, object: player)
		NotificationCenter.default.addObserver(self, selector: #selector(playbackDidFinish(_:)), name: Notification.Name.FSPlayerDidFinish, object: player)
	}
	
	private func removeObservers() {
		NotificationCenter.default.removeObserver(self, name: Notification.Name.FSPlayerIsPreparedToPlay, object: player)
		NotificationCenter.default.removeObserver(self, name: Notification.Name.FSPlayerLoadStateDidChange, object: player)
		NotificationCenter.default.removeObserver(self, name: Notification.Name.FSPlayerPlaybackStateDidChange, object: player)
		NotificationCenter.default.removeObserver(self, name: Notification.Name.FSPlayerDidFinish, object: player)
	}
	
	@objc private func playerPreparedToPlay(_ notification: Notification) {
		print("🎥 FS_PLAYER is prepared to play")
		Task { @MainActor in
			self.eventContinuation?.yield(.readyToPlay)
		}
	}
	
	@objc private func loadStateDidChange(_ notification: Notification) {
		guard let player = player else {
			return
		}
		
		Task { @MainActor in
			switch player.loadState {
			case .playable:
				print("🎥 FS_PLAYER is playable")
				
			case .playthroughOK:
				print("🎥 FS_PLAYER played through ok")
				
			case .stalled:
				print("🎥 FS_PLAYER is stalled")
				self.eventContinuation?.yield(.buffering(true))
				
			default:
				print("🎥 FS_PLAYER load state unknown")
			}
		}
	}
	
	@objc private func playbackStateDidChange(_ notification: Notification) {
		guard let player = player else {
			return
		}
		
		Task { @MainActor in
			switch player.playbackState {
			case .playing:
				print("🎥 FS_PLAYER is playing")
				self.eventContinuation?.yield(.didStartPlaying)
				self.startTimeTracking()
				
			case .paused:
				print("🎥 FS_PLAYER is paused")
				self.eventContinuation?.yield(.didPause)
				self.startTimeTracking()
				
			case .stopped:
				print("🎥 FS_PLAYER is stopped")
				self.eventContinuation?.yield(.didStop)
				self.startTimeTracking()
				
			case .interrupted:
				print("🎥 FS_PLAYER is interrupted")
				self.startTimeTracking()
				
			case .seekingForward:
				print("🎥 FS_PLAYER is seeking forward")
				
			case .seekingBackward:
				print("🎥 FS_PLAYER is seeking backward")
				
			default:
				print("🎥 FS_PLAYER playback state unknown")
				self.eventContinuation?.yield(.idle)
			}
		}
	}
	
	@objc private func playbackDidFinish(_ notification: Notification) {
		print("🎥 FS_PLAYER Playback finished")
	}
	
	private func startTimeTracking() {
		stopTimeTracking()
		
		guard let player = self.player else {
			return
		}
		
		let isPlaying = player.isPlaying()
		let current = player.currentPlaybackTime
		let duration = player.duration
		
		timeTask = Task.detached {
			while !(Task.isCancelled) {
				try? await Task.sleep(nanoseconds: 1_000_000_000)
				print("🎥 FS_PLAYER is playing: \(isPlaying) - current: \(current), duration: \(duration)")
				await MainActor.run {
					let record = MediaPlayerClient.TimeRecord(current: current, duration: duration)
					self.timeContinuation?.yield(record)
				}
			}
		}
	}
	
	private func stopTimeTracking() {
		timeTask?.cancel()
		timeTask = nil
	}
}
*/
