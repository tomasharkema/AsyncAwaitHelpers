//
//  Task.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/11/2021.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
  static func sleep(time: TimeInterval) async throws {
    try await Task.sleep(nanoseconds: UInt64(time * 1_000_000_000))
  }
}
