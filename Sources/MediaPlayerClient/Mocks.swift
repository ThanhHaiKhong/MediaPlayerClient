//
//  Mocks.swift
//  MediaPlayerClient
//
//  Created by Thanh Hai Khong on 18/4/25.
//

import Dependencies

extension DependencyValues {
    public var mediaPlayerClient: MediaPlayerClient {
        get { self[MediaPlayerClient.self] }
        set { self[MediaPlayerClient.self] = newValue }
    }
}

extension MediaPlayerClient: TestDependencyKey {
    public static var testValue: MediaPlayerClient {
        MediaPlayerClient()
    }
    
    public static var previewValue: MediaPlayerClient {
        return MediaPlayerClient()
    }
}
