// The Swift Programming Language
// https://docs.swift.org/swift-book

import ComposableArchitecture
import Foundation
import UIKit

@DependencyClient
public struct MediaPlayerClient: Sendable {
    public var initialize: @Sendable (_ containerView: UIView, _ playMode: PlayMode?) async throws -> Void
    
    public var setTrack: @Sendable (_ url: URL) async throws -> Void
    
    public var currentRate: @Sendable () async throws -> Float
    
    public var setPlaybackRate: @Sendable (_ rate: Float) async throws -> Void
    
    public var play: @Sendable () async throws -> Void
    
    public var pause: @Sendable () async throws -> Void
    
    public var stop: @Sendable () async throws -> Void
    
    public var seek: @Sendable (_ time: TimeInterval) async throws -> Void
    
    public var switchMode: @Sendable (_ playMode: PlayMode) async throws -> Void
    
    public var currentTime: @Sendable () -> AsyncStream<TimeRecord> = {
        AsyncStream { _ in }
    }
    
    public var duration: @Sendable () async throws -> TimeInterval
    
    public var events: @Sendable () -> AsyncStream<PlaybackEvent> = {
        AsyncStream { _ in
            
        }
    }
	
	public var isEqualizerEnabled: @Sendable () async -> Bool = {
		false
	}
    
    public var setEnableEqualizer: @Sendable (_ enabled: Bool) async throws -> Void
    
    public var setListEQ: @Sendable (_ listEQ: [Float]) async throws -> Void
    
    public var setEqualizer: @Sendable (_ value: Float, _ bandIndex: Int) async throws -> Void
}
