//
//  TaskGroup.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 10/06/2021.
//

import Foundation

public func whenAny<T, D, R>(_ tasks: [() -> Task<T?, Error>], initial: D, done: (inout D, T) async -> R?) async throws -> R? {
  var initialMutable = initial
  return try await withThrowingTaskGroup(of: T?.self) { group in
    for task in tasks {
      _ = group.addTaskUnlessCancelled {
        try Task.checkCancellation()
        return try await task().value
      }
    }

    for try await result in group {
      if let result = result, let ret = await done(&initialMutable, result) {
        group.cancelAll()
        return ret
      }
    }

    return nil
  }
}

public func whenAny<T>(_ tasks: [() -> Task<T?, Error>]) async throws -> T? {
  return try await whenAny(tasks, initial: (), done: { _, r in
    return r
  })
}

public func whenAny<T, D, R>(_ tasks: [() async throws -> T?], initial: D, done: (inout D, T) async -> R?) async throws -> R? {
  return try await whenAny(tasks.lazy.map { el in
    return {
      Task {
        try await el()
      }
    }
  }, initial: initial, done: done)
}

public func whenAny<T>(_ tasks: [() async throws -> T?]) async throws -> T? {
  return try await whenAny(tasks, initial: (), done: { _, r in
    return r
  })
}

public func whenAny<T, D, R>(_ tasks: [Task<T?, Error>], initial: D, done: (inout D, T) async -> R?) async throws -> R? {
  return try await whenAny(tasks.map { el in
    return {
      try await el.value
    }
  }, initial: initial, done: done)
}

public func whenAny<T>(_ tasks: [Task<T?, Error>]) async throws -> T? {
  return try await whenAny(tasks, initial: (), done: { _, r in
    return r
  })
}

// MARK: whenBoth

public func whenBoth<A, B>(
  _ a: @autoclosure () -> Task<A, Error>,
  _ b: @autoclosure () -> Task<B, Error>
) async throws -> (A, B) {
  async let aResult = a().value
  async let bResult = b().value

  return try await (aResult, bResult)
}

public func whenBoth<A, B>(
  _ a: @autoclosure @escaping () async throws -> A,
  _ b: @autoclosure @escaping () async throws -> B
) async throws -> (A, B) {
  return try await whenBoth(Task { try await a() }, Task { try await b() })
}

// MARK: whenAll

func whenAll<T>(_ tasks: [() -> Task<T, Error>]) async throws -> [T] {
  try await withThrowingTaskGroup(of: [T].self) { group in
    for task in tasks {
      _ = group.addTaskUnlessCancelled {
        return [try await task().value]
      }
    }
    return try await group.reduce([], +)
  }
}

func whenAll<T>(_ tasks: [() async throws -> T]) async throws -> [T] {
  return try await whenAll(tasks.map { el in
    return {
      Task {
        try await el()
      }
    }
  })
}

func whenAll<T>(_ tasks: [Task<T, Error>]) async throws -> [T] {
  return try await whenAll(tasks.map { el in
    return {
      try await el.value
    }
  })
}

public extension Array {
  func whenAny<T, D, R>(initial: D, done: (inout D, T) async -> R?) async throws -> R? where Element == Task<T?, Error> {
    return try await AsyncAwaitHelpers.whenAny(self, initial: initial, done: done)
  }

  func whenAny<T, D, R>(initial: D, done: (inout D, T) async -> R?) async throws -> R? where Element == (() -> Task<T?, Error>) {
    return try await AsyncAwaitHelpers.whenAny(self, initial: initial, done: done)
  }

  func whenAny<T, D, R>(initial: D, done: (inout D, T) async -> R?) async throws -> R? where Element == (() async throws -> T?) {
    return try await AsyncAwaitHelpers.whenAny(self, initial: initial, done: done)
  }

  func whenAny<T>() async throws -> T? where Element == Task<T?, Error> {
    return try await AsyncAwaitHelpers.whenAny(self)
  }

  func whenAny<T>() async throws -> T? where Element == () -> Task<T?, Error> {
    return try await AsyncAwaitHelpers.whenAny(self)
  }

  func whenAny<T>() async throws -> T? where Element == () async throws -> T? {
    return try await AsyncAwaitHelpers.whenAny(self)
  }

  func whenAll<T>() async throws -> [T] where Element == Task<T, Error> {
    return try await AsyncAwaitHelpers.whenAll(self)
  }

  func whenAll<T>() async throws -> [T] where Element == (() -> Task<T, Error>) {
    return try await AsyncAwaitHelpers.whenAll(self)
  }

  func whenAll<T>() async throws -> [T] where Element == (() async throws -> T) {
    return try await AsyncAwaitHelpers.whenAll(self)
  }
}
