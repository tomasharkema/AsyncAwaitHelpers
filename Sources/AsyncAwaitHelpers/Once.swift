//
//  Once.swift
//  
//
//  Created by Tomas Harkema on 11/11/2021.
//

import Foundation

public struct NoKey: Hashable {}

public typealias OnceSingle<Value, Error: Swift.Error> = Once<NoKey, Value, Error>

public actor Once<Key: Hashable, Value, Error: Swift.Error> {
  public init() {}

  private var task: [Key: (Date, Task<Value, Error>)] = [:]

  @discardableResult
  public func onceKeepOriginal(key: Key, keepInCache: TimeInterval? = nil, _ handler: @autoclosure () -> Task<Value, Error>) -> Task<Value, Error> {
    if let task = task[key] {
      guard let keepInCache = keepInCache else {
        return task.1
      }

      if abs(task.0.timeIntervalSinceNow) < keepInCache {
        return task.1
      }
    }

    let newTask = handler()
    let date = Date()

    Task {
      _ = await newTask.result
      if let keepInCache = keepInCache {
        let sleep = max(0, keepInCache - abs(date.timeIntervalSinceNow))
        print("SLEEP FOR \(sleep)")
        try await Task.sleep(time: sleep)
        print("SLEPT! INVALIDATING")
      }
      self.task[key] = nil
    }

    task[key] = (date, newTask)
    return newTask
  }


  @discardableResult
  public func onceKeepOriginal(keepInCache: TimeInterval? = nil, _ handler: @autoclosure () -> Task<Value, Error>) -> Task<Value, Error> where Key == NoKey {
    return onceKeepOriginal(key: NoKey(), keepInCache: keepInCache, handler())
  }

  @discardableResult
  public nonisolated func onceKeepOriginal(key: Key, keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async throws -> Value) async
  -> Task<Value, Error> where Error == Swift.Error
  {
    await onceKeepOriginal(key: key, keepInCache: keepInCache, Task {
      try await handler()
    })
  }

  @discardableResult
  public nonisolated func onceKeepOriginal(keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async throws -> Value) async
  -> Task<Value, Error> where Error == Swift.Error, Key == NoKey
  {
    return await onceKeepOriginal(key: NoKey(), keepInCache: keepInCache, handler)
  }

  @discardableResult
  public nonisolated func onceKeepOriginal(key: Key, keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never
  {
    await onceKeepOriginal(key: key, keepInCache: keepInCache, Task {
      await handler()
    })
  }

  @discardableResult
  public nonisolated func onceKeepOriginal(keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never, Key == NoKey
  {
    await onceKeepOriginal(key: NoKey(), keepInCache: keepInCache, handler)
  }

  @discardableResult
  public func onceCancelOriginal(key: Key, _ handler: @autoclosure () -> Task<Value, Error>) -> Task<Value, Error> {
    task[key]?.1.cancel()
    task[key] = nil

    let newTask = handler()

    Task {
      _ = await newTask.result
      self.task[key] = nil
    }

    task[key] = (Date(), newTask)
    return newTask
  }

  @discardableResult
  public func onceCancelOriginal(_ handler: @autoclosure () -> Task<Value, Error>) -> Task<Value, Error> where Key == NoKey {
    return onceCancelOriginal(key: NoKey(), handler())
  }

  @discardableResult
  public nonisolated func onceCancelOriginal(
    key: Key, _ handler: @escaping @Sendable () async throws -> Value
  ) async -> Task<Value, Error> where Error == Swift.Error
  {
    await onceCancelOriginal(key: key,Task {
      try await handler()
    })
  }

  @discardableResult
  public nonisolated func onceCancelOriginal(
    _ handler: @escaping @Sendable () async throws -> Value
  ) async -> Task<Value, Error> where Error == Swift.Error, Key == NoKey
  {
    await onceCancelOriginal(key: NoKey(), handler)
  }

  @discardableResult
  public nonisolated func onceCancelOriginal(key: Key, _ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never
  {
    await onceCancelOriginal(key: key, Task {
      let handler = handler
      return await handler()
    })
  }

  @discardableResult
  public nonisolated func onceCancelOriginal(_ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never, Key == NoKey
  {
    await onceCancelOriginal(key: NoKey(), handler)
  }

  private func _cancel(key: Key) {
    task[key]?.1.cancel()
    task[key] = nil
  }

  private func _cancelAll() {
    for task in task {
      task.value.1.cancel()
    }
    task = [:]
  }

  public nonisolated func cancel(key: Key) {
    Task {
      await _cancel(key: key)
    }
  }

  public nonisolated func cancel() where Key == NoKey {
    cancel(key: NoKey())
  }

  public nonisolated func cancelAll() {
    Task {
      await _cancelAll()
    }
  }
}

