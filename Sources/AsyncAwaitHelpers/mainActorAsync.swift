//
//  mainActorAsync.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/11/2021.
//

import Foundation

public func mainActorAsync(
  priority: TaskPriority? = nil,
  _ handler: @MainActor @Sendable @escaping () throws -> Void
) {
  Task(priority: priority) {
    try await MainActor.run(body: handler)
  }
}
