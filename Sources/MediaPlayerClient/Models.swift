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
		case equalizerNotEnabled
		case invalidEqualizerBandIndex
		case invalidEqualizerBandCount
		case invalidEqualizerPreset
		case mediaNotSet
    }
}

// MARK: - AudioEqualizer

extension MediaPlayerClient {
	public struct AudioEqualizer: Equatable, Sendable, Hashable {
		public static let presets: [MediaPlayerClient.AudioEqualizer.Preset] = [.flat, .classical, .club, .dance, .fullBass, .fullBassTreble, .fullTreble, .headphones, .largeHall, .live, .party, .pop, .raggae, .rock, .ska, .soft, .softRock, .techno]
		public var preAmplification: Float // PreAmp value (-20.0 to 20.0 Hz)
		public var bands: [MediaPlayerClient.AudioEqualizer.Band] = MediaPlayerClient.AudioEqualizer.Band.allBands
	}
}

extension MediaPlayerClient.AudioEqualizer {
	public struct Preset: Equatable, Sendable, Hashable {
		public let name: String
		public let index: UInt32
	}
	
	public struct Band: Equatable, Sendable, Hashable {
		public var frequency: Float
		public var amplification: Float
		public var index: UInt32
	}
}

extension MediaPlayerClient.AudioEqualizer.Preset {
	public static let flat = MediaPlayerClient.AudioEqualizer.Preset(name: "Flat", index: 0)
	public static let classical = MediaPlayerClient.AudioEqualizer.Preset(name: "Classical", index: 1)
	public static let club = MediaPlayerClient.AudioEqualizer.Preset(name: "Club", index: 2)
	public static let dance = MediaPlayerClient.AudioEqualizer.Preset(name: "Dance", index: 3)
	public static let fullBass = MediaPlayerClient.AudioEqualizer.Preset(name: "Full Bass", index: 4)
	public static let fullBassTreble = MediaPlayerClient.AudioEqualizer.Preset(name: "Full Bass Treble", index: 5)
	public static let fullTreble = MediaPlayerClient.AudioEqualizer.Preset(name: "Full Treble", index: 6)
	public static let headphones = MediaPlayerClient.AudioEqualizer.Preset(name: "Headphones", index: 7)
	public static let largeHall = MediaPlayerClient.AudioEqualizer.Preset(name: "Large Hall", index: 8)
	public static let live = MediaPlayerClient.AudioEqualizer.Preset(name: "Live", index: 9)
	public static let party = MediaPlayerClient.AudioEqualizer.Preset(name: "Party", index: 10)
	public static let pop = MediaPlayerClient.AudioEqualizer.Preset(name: "Pop", index: 11)
	public static let raggae = MediaPlayerClient.AudioEqualizer.Preset(name: "Raggae", index: 12)
	public static let rock = MediaPlayerClient.AudioEqualizer.Preset(name: "Rock", index: 13)
	public static let ska = MediaPlayerClient.AudioEqualizer.Preset(name: "Ska", index: 14)
	public static let soft = MediaPlayerClient.AudioEqualizer.Preset(name: "Soft", index: 15)
	public static let softRock = MediaPlayerClient.AudioEqualizer.Preset(name: "Soft Rock", index: 16)
	public static let techno = MediaPlayerClient.AudioEqualizer.Preset(name: "Techno", index: 17)
}

extension MediaPlayerClient.AudioEqualizer.Band {
	public static let allBands: [MediaPlayerClient.AudioEqualizer.Band] = [
		MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 0.000000, index: 0),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 0.000000, index: 1),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 0.000000, index: 2),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 0.000000, index: 3),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 0.000000, index: 4),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 0.000000, index: 5),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 0.000000, index: 6),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 0.000000, index: 7),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 0.000000, index: 8),
		MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 0.000000, index: 9)
	]
	
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

extension MediaPlayerClient.AudioEqualizer {
	public static let flat = MediaPlayerClient.AudioEqualizer(
		preAmplification: 0.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 0.000000, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 0.000000, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 0.000000, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 0.000000, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 0.000000, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 0.000000, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 0.000000, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 0.000000, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 0.000000, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 0.000000, index: 9)
		]
	)
	
	public static let classical = MediaPlayerClient.AudioEqualizer(
		preAmplification: -3.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -1.11022e-15, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: -1.11022e-15, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -1.11022e-15, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -1.11022e-15, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -1.11022e-15, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -1.11022e-15, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -7.200000, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -7.200000, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -7.200000, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -9.600000, index: 9)
		]
	)
	
	public static let club = MediaPlayerClient.AudioEqualizer(
		preAmplification: -2.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -1.11022e-15, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: -1.11022e-15, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 8.0, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 5.6, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 5.6, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 5.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 3.2, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -1.11022e-15, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -1.11022e-15, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -1.11022e-15, index: 9)
		]
	)
	
	public static let dance = MediaPlayerClient.AudioEqualizer(
		preAmplification: -4.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 9.6, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 7.2, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 2.4, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -1.11022e-15, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -1.11022e-15, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -5.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -7.2, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -7.2, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -1.11022e-15, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -1.11022e-15, index: 9)
		]
	)
	
	public static let fullBass = MediaPlayerClient.AudioEqualizer(
		preAmplification: -6.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -8.0, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 9.6, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 9.6, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 5.6, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 1.6, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -4.0, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -8.0, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -10.4, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -11.2, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -11.2, index: 9)
		]
	)
	
	public static let fullBassTreble = MediaPlayerClient.AudioEqualizer(
		preAmplification: -6.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 7.2, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 5.6, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -1.11022e-15, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -7.2, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -4.8, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 1.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 8.0, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 11.2, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 12.0, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 12.0, index: 9)
		]
	)
	
	public static let fullTreble = MediaPlayerClient.AudioEqualizer(
		preAmplification: -8.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -9.6, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: -9.6, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -9.6, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -4.0, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 2.4, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 11.2, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 16.0, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 16.0, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 16.0, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 16.8, index: 9)
		]
	)
	
	public static let headphones = MediaPlayerClient.AudioEqualizer(
		preAmplification: -5.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 4.8, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 11.2, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 5.6, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -3.2, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -2.4, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 1.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 4.8, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 9.6, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 12.8, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 14.4, index: 9)
		]
	)
	
	public static let largeHall = MediaPlayerClient.AudioEqualizer(
		preAmplification: -4.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 10.4, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 10.4, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 5.6, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 5.6, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -1.11022e-15, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -4.8, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -4.8, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -4.8, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -1.11022e-15, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -1.11022e-15, index: 9)
		]
	)
	
	public static let live = MediaPlayerClient.AudioEqualizer(
		preAmplification: -2.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -4.8, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: -1.11022e-15, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 4.0, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 5.6, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 5.6, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 5.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 4.0, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 2.4, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 2.4, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 2.4, index: 9)
		]
	)
	
	public static let party = MediaPlayerClient.AudioEqualizer(
		preAmplification: -3.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 7.2, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 7.2, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -1.11022e-15, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -1.11022e-15, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -1.11022e-15, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -1.11022e-15, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -1.11022e-15, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -1.11022e-15, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 7.2, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 7.2, index: 9)
		]
	)
	
	public static let pop = MediaPlayerClient.AudioEqualizer(
		preAmplification: -3.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -1.6, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 4.8, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 7.2, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: 8.0, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 5.6, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -1.11022e-15, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -2.4, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -2.4, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -1.6, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -1.6, index: 9)
		]
	)
	
	public static let raggae = MediaPlayerClient.AudioEqualizer(
		preAmplification: -1.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -1.11022e-15, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: -1.11022e-15, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -1.11022e-15, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -5.6, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -1.11022e-15, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 6.4, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 6.4, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -1.11022e-15, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: -1.11022e-15, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: -1.11022e-15, index: 9)
		]
	)
	
	public static let rock = MediaPlayerClient.AudioEqualizer(
		preAmplification: -5.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 8.0, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 4.8, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -5.6, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -8.0, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -3.2, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 4.0, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 8.8, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 11.2, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 11.2, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 11.2, index: 9)
		]
	)
	
	public static let ska = MediaPlayerClient.AudioEqualizer(
		preAmplification: -3.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: -2.4, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: -4.8, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -4.0, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -1.11022e-15, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: 4.0, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 5.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 8.8, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 9.6, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 11.2, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 9.6, index: 9)
		]
	)
	
	public static let soft = MediaPlayerClient.AudioEqualizer(
		preAmplification: -2.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 4.8, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 1.6, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -1.11022e-15, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -2.4, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -1.11022e-15, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: 4.0, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 8.0, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 9.6, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 11.2, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 12.0, index: 9)
		]
	)
	
	public static let softRock = MediaPlayerClient.AudioEqualizer(
		preAmplification: -2.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 4.0, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 4.0, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: 2.4, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -1.11022e-15, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -4.0, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -5.6, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: -3.2, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: -1.11022e-15, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 2.4, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 8.8, index: 9)
		]
	)
	
	public static let techno = MediaPlayerClient.AudioEqualizer(
		preAmplification: -5.0,
		bands: [
			MediaPlayerClient.AudioEqualizer.Band(frequency: 31.250000, amplification: 8.0, index: 0),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 62.500000, amplification: 5.6, index: 1),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 125.000000, amplification: -1.11022e-15, index: 2),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 250.000000, amplification: -5.6, index: 3),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 500.000000, amplification: -4.8, index: 4),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 1000.000000, amplification: -1.11022e-15, index: 5),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 2000.000000, amplification: 8.0, index: 6),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 4000.000000, amplification: 9.6, index: 7),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 8000.000000, amplification: 9.6, index: 8),
			MediaPlayerClient.AudioEqualizer.Band(frequency: 16000.000000, amplification: 8.8, index: 9)
		]
	)
}

extension MediaPlayerClient.AudioEqualizer.Preset {
	public func toEqualizer() -> MediaPlayerClient.AudioEqualizer {
		switch self {
		case .flat:
			return .flat
		case .classical:
			return .classical
		case .club:
			return .club
		case .dance:
			return .dance
		case .fullBass:
			return .fullBass
		case .fullBassTreble:
			return .fullBassTreble
		case .fullTreble:
			return .fullTreble
		case .headphones:
			return .headphones
		case .largeHall:
			return .largeHall
		case .live:
			return .live
		case .party:
			return .party
		case .pop:
			return .pop
		case .raggae:
			return .raggae
		case .rock:
			return .rock
		case .ska:
			return .ska
		case .soft:
			return .soft
		case .softRock:
			return .softRock
		case .techno:
			return .techno
		default:
			fatalError("Unknown preset")
		}
	}
}

/**
 🔊 Khái niệm:
 •	preAmplification (tiếng Việt gọi là khuếch đại trước) là mức khuếch đại hoặc giảm âm áp dụng lên toàn bộ tín hiệu âm thanh, trước khi đi qua các band EQ cụ thể (31Hz, 62Hz, …).
 •	Giá trị này có thể là dương (khuếch đại), hoặc âm (giảm âm).
 
 📊 Vai trò:
 •	Tránh clipping (âm thanh bị méo tiếng do vượt quá ngưỡng cho phép).
 •	Cân bằng tổng thể khi có nhiều band được boost lên cao.
 •	Giúp tăng/làm nhỏ âm lượng tổng thể của output mà không thay đổi từng band.
 */
