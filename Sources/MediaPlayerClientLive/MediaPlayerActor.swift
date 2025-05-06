//
//  MediaPlayerActor.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 21/4/25.
//

import MediaPlayerClient
import ZFPlayerObjC
import AVFoundation
import Foundation
import UIKit

@MainActor
final internal class MediaPlayerActor: Sendable {
    
    // MARK: - Properties
    
    private var player: ZFPlayerController?
    private var eventContinuation: AsyncStream<MediaPlayerClient.PlaybackEvent>.Continuation?
	private var timeContinuation: AsyncStream<MediaPlayerClient.TimeRecord>.Continuation?
    private var currentURL: URL?
    private var containerView: UIView?
    private var playMode: MediaPlayerClient.PlayMode = .video
    private var isEnabledEqualizer: Bool = false
    
    private lazy var audioManager: ZFIJKPlayerManager = {
        let manager = ZFIJKPlayerManager()
        return manager
    }()
    
    private lazy var videoManager: ZFAVPlayerManager = {
        let manager = ZFAVPlayerManager()
        return manager
    }()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func initialize(containerView: UIView, playMode: MediaPlayerClient.PlayMode?) async throws {
        self.containerView = containerView
        let effectivePlayMode = playMode ?? self.playMode
        self.playMode = effectivePlayMode
        try setupPlayer(containerView: containerView, playMode: effectivePlayMode)
    }
    
    private func setupPlayer(containerView: UIView, playMode: MediaPlayerClient.PlayMode) throws {
        let playerManager: ZFPlayerMediaPlayback
        switch playMode {
        case .audioOnly:
            playerManager = videoManager
        case .video:
            playerManager = videoManager
        }
		
		let controlView = ZFPlayerControlView(frame: containerView.bounds)
		containerView.addSubview(controlView)
        
        player = ZFPlayerController(playerManager: playerManager, containerView: containerView)
        player?.pauseWhenAppResignActive = false
        player?.allowOrentitaionRotation = playMode == .video
		player?.controlView = controlView
        
        // Set up callbacks
        player?.playerPlayStateChanged = { [weak self] player, state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .playStatePlaying:
                    self.eventContinuation?.yield(.didStartPlaying)
                case .playStatePaused:
                    self.eventContinuation?.yield(.didPause)
                case .playStatePlayStopped:
                    self.eventContinuation?.yield(.didStop)
                case .playStatePlayFailed:
                    self.eventContinuation?.yield(.error(MediaPlayerClient.PlayerError.playbackFailed))
                case .playStateUnknown:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        player?.playerReadyToPlay = { [weak self] player, assetURL in
            Task { @MainActor in
                guard let self else { return }
                self.eventContinuation?.yield(.readyToPlay)
            }
        }
        
        player?.playerPlayTimeChanged = { [weak self] _, currentTime, duration in
            Task { @MainActor in
				let timeRecord = MediaPlayerClient.TimeRecord(currentTime: currentTime, duration: duration)
                self?.timeContinuation?.yield(timeRecord)
            }
        }
        
        player?.playerLoadStateChanged = { [weak self] _, loadState in
            Task { @MainActor in
                guard let self else { return }
                let isBuffering = loadState.contains(.prepare) || loadState.contains(.stalled)
                self.eventContinuation?.yield(.buffering(isBuffering))
            }
        }
		
		player?.playerDidToEnd = { [weak self] player in
			Task { @MainActor in
				guard let self else { return }
				self.eventContinuation?.yield(.didToEnd)
			}
		}
    }
    
    func setTrack(url: URL) async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        
        // Validate URL
        guard url.isFileURL || (url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https") else {
            throw MediaPlayerClient.PlayerError.invalidURL
        }
        
        let wasPlaying = player.currentPlayerManager.isPlaying
        player.currentPlayerManager.stop()
        player.assetURL = url
        
        if wasPlaying {
            player.currentPlayerManager.play()
        }
    }
    
    func setPlaybackRate(_ rate: Float) async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        player.currentPlayerManager.rate = rate
    }
    
    func switchMode(to playMode: MediaPlayerClient.PlayMode) async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        let shouldAutoPlay = player.currentPlayerManager.shouldAutoPlay
        let rate = player.currentPlayerManager.rate
        
        switch playMode {
        case .audioOnly:
            player.replaceCurrentPlayerManager(videoManager)
        case .video:
            player.replaceCurrentPlayerManager(videoManager)
        }
        
        player.currentPlayerManager.rate = rate
        player.currentPlayerManager.shouldAutoPlay = shouldAutoPlay
        player.allowOrentitaionRotation = playMode == .video
        player.containerView?.isHidden = playMode == .audioOnly
		player.controlView?.isHidden = playMode == .audioOnly
    }
    
    func play() async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        guard player.assetURL != nil else { throw MediaPlayerClient.PlayerError.invalidURL }
        player.currentPlayerManager.play()
    }
    
    func pause() async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        player.currentPlayerManager.pause()
    }
    
    func stop() async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        player.stop()
        self.player = nil
    }
    
    func seek(to time: TimeInterval) async throws {
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
    }
    
    func playbackState() async throws -> MediaPlayerClient.PlaybackState {
        guard let player else { return .unknown }
        let playerManager = player.currentPlayerManager
        
        switch playerManager.playState {
        case .playStatePlaying:
            return .playing
            
        case .playStatePaused:
            return .paused
            
        case .playStatePlayStopped:
            return .stopped
            
        case .playStatePlayFailed:
            return .failed(MediaPlayerClient.PlayerError.playbackFailed)
            
        case .playStateUnknown:
            return .unknown
            
        default:
            return .unknown
        }
    }
    
    func currentRate() async throws -> Float {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        return player.currentPlayerManager.rate
    }
    
    func duration() async throws -> TimeInterval {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        return player.totalTime
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
    
    func setEnableEqualizer(_ enabled: Bool) async throws {
        isEnabledEqualizer = enabled

        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        if let playerManager = player.currentPlayerManager as? ZFAVPlayerManager {
			playerManager.setEnableEQ(enabled)
        }
    }
	
	func isEqualizerEnabled() async -> Bool {
		return isEnabledEqualizer
	}
    
    func setListEQ(_ listEQ: [Float]) async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        
        if let videoManager = player.currentPlayerManager as? ZFAVPlayerManager {
            videoManager.listEQ = listEQ
        }
        
        if let audioManager = player.currentPlayerManager as? ZFIJKPlayerManager {
            audioManager.listEQ = listEQ
        }
    }
    
    func setEqualizer(_ value: Float, _ bandIndex: Int) async throws {
        guard let player else { throw MediaPlayerClient.PlayerError.notInitialized }
        if let playerManager = player.currentPlayerManager as? ZFAVPlayerManager {
			playerManager.setEqualizerValue(value, forBand: bandIndex)
        }
    }
}
