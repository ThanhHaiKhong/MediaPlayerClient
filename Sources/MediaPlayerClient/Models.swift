//
//  Models.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 21/4/25.
//

import Foundation

// MARK: - Supporting Types

extension MediaPlayerClient {
	public typealias TimeRecord = (TimeInterval, TimeInterval)
	
    public enum PlayMode: Int, Equatable, Sendable {
        case audioOnly
        case video
    }
    
    public enum PlaybackState: Equatable, Sendable {
        case unknown
        case playing
        case paused
        case stopped
        case failed(Error)
        
        public static func == ( lhs: PlaybackState, rhs: PlaybackState) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown),
                 (.playing, .playing),
                 (.paused, .paused),
                 (.stopped, .stopped):
                return true
            case let (.failed(lhsError), .failed(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    public enum PlaybackEvent: Equatable, Sendable {
		case idle
        case readyToPlay
        case didStartPlaying
        case didPause
        case didStop
        case didFinish
		case didToEnd
        case buffering(Bool)
        case error(Error)
        
        public static func == (lhs: PlaybackEvent, rhs: PlaybackEvent) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
				 (.readyToPlay, .readyToPlay),
                 (.didStartPlaying, .didStartPlaying),
                 (.didPause, .didPause),
                 (.didStop, .didStop),
				 (.didFinish, .didFinish),
				 (.didToEnd, .didToEnd):
                return true
            case let (.buffering(lhsBuffering), .buffering(rhsBuffering)):
                return lhsBuffering == rhsBuffering
            case let (.error(lhsError), .error(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    public enum PlayerError: Error, Equatable, Sendable {
        case notInitialized
        case playbackFailed
        case seekFailed
        case invalidURL
        case missingContainerView
    }
    
    public typealias EqualizerFrequency = Float // in Hz (e.g., 32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000)
    
    public struct EqualizerBand: Equatable, Sendable, Hashable {
        public let frequency: EqualizerFrequency
        public var gain: Float // in dB (e.g., -12 to +12)
        
        public init(frequency: Float, gain: Float) {
            self.frequency = frequency
            self.gain = gain
        }
		
		public var displayFrequency: String {
			if frequency >= 1000 {
				let kHz = frequency / 1000
				if kHz.truncatingRemainder(dividingBy: 1) == 0 {
					// Nếu là số nguyên (ví dụ 2000 -> 2K)
					return "\(Int(kHz))K"
				} else {
					// Nếu là số thập phân (ví dụ 2500 -> 2.5K)
					return String(format: "%.1fK", kHz)
				}
			} else {
				return "\(Int(frequency))"
			}
		}
    }
    
    public struct EqualizerPreset: Equatable, Sendable, Hashable {
        public let name: String
        public let widthType: String
        public let width: Float
        public let bands: [MediaPlayerClient.EqualizerBand]
        
        public init(name: String, widthType: String, width: Float, bands: [MediaPlayerClient.EqualizerBand]) {
            self.name = name
            self.widthType = widthType
            self.width = width
            self.bands = bands
        }
    }
}

extension MediaPlayerClient.EqualizerBand {
	public static let `default`: [MediaPlayerClient.EqualizerBand] = [
		MediaPlayerClient.EqualizerBand(frequency: 32, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 64, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 125, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 250, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 500, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 0),
		MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
	]
}

extension MediaPlayerClient.EqualizerFrequency {
    public static let allFrequencies: [MediaPlayerClient.EqualizerFrequency] = [
        32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
    ]
    
    public static let allFrequenciesString: [String] = [
        "32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"
    ]
}

extension MediaPlayerClient.EqualizerPreset {
    public static let bass = MediaPlayerClient.EqualizerPreset(
        name: "Bass",
        widthType: "o",
        width: 1.5,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 6),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: -1),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: -3)
        ]
    )
    
    public static let bassPlus = MediaPlayerClient.EqualizerPreset(
        name: "Bass++",
        widthType: "o",
        width: 1.5,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 12),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 9),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 6),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: -1),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: -3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: -3),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: -4),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: -5)
        ]
    )
    
    public static let acoustic = MediaPlayerClient.EqualizerPreset(
        name: "Acoustic",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: -3),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let classical = MediaPlayerClient.EqualizerPreset(
        name: "Classical",
        widthType: "o",
        width: 1.0,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let flat = MediaPlayerClient.EqualizerPreset(
        name: "Flat",
        widthType: "o",
        width: 1.0,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let dance = MediaPlayerClient.EqualizerPreset(
        name: "Dance",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 4)
        ]
    )
    
    public static let deep = MediaPlayerClient.EqualizerPreset(
        name: "Deep",
        widthType: "o",
        width: 1.5,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 8),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 7),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: -1),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: -3),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: -4),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: -5)
        ]
    )
    
    public static let electronic = MediaPlayerClient.EqualizerPreset(
        name: "Electronic",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 6),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 5)
        ]
    )
    
    public static let hipHop = MediaPlayerClient.EqualizerPreset(
        name: "Hip Hop",
        widthType: "o",
        width: 1.3,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 7),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 6),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: -1),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: -3),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: -4)
        ]
    )
    
    public static let jazz = MediaPlayerClient.EqualizerPreset(
        name: "Jazz",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: -1),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let loudness = MediaPlayerClient.EqualizerPreset(
        name: "Loudness",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 6),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 6)
        ]
    )
    
    public static let lounge = MediaPlayerClient.EqualizerPreset(
        name: "Lounge",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let pop = MediaPlayerClient.EqualizerPreset(
        name: "Pop",
        widthType: "o",
        width: 1.1,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let rock = MediaPlayerClient.EqualizerPreset(
        name: "Rock",
        widthType: "o",
        width: 1.2,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 2)
        ]
    )
    
    public static let spokenWord = MediaPlayerClient.EqualizerPreset(
        name: "Spoken Word",
        widthType: "o",
        width: 1.5,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: -4),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: -3),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: -2),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: 0)
        ]
    )
    
    public static let edm = MediaPlayerClient.EqualizerPreset(
        name: "EDM",
        widthType: "o",
        width: 1.5,
        bands: [
            MediaPlayerClient.EqualizerBand(frequency: 32, gain: 8),
            MediaPlayerClient.EqualizerBand(frequency: 64, gain: 7),
            MediaPlayerClient.EqualizerBand(frequency: 125, gain: 6),
            MediaPlayerClient.EqualizerBand(frequency: 250, gain: 5),
            MediaPlayerClient.EqualizerBand(frequency: 500, gain: 4),
            MediaPlayerClient.EqualizerBand(frequency: 1000, gain: 3),
            MediaPlayerClient.EqualizerBand(frequency: 2000, gain: 2),
            MediaPlayerClient.EqualizerBand(frequency: 4000, gain: 1),
            MediaPlayerClient.EqualizerBand(frequency: 8000, gain: 0),
            MediaPlayerClient.EqualizerBand(frequency: 16000, gain: -1)
        ]
    )
    
    public static let allPresets: [MediaPlayerClient.EqualizerPreset] = [.bass, .bassPlus, .acoustic, .classical, .flat, .dance, .deep, .electronic, .hipHop, .jazz, .loudness, .lounge, .pop, .rock, .spokenWord, edm]
}
