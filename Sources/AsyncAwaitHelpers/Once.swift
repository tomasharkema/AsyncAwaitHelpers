//
//  Once.swift
//  
//
//  Created by Tomas Harkema on 11/11/2021.
//

import Foundation

public struct NoKey: Hashable {}

public typealias OnceSingle<Value, Error: Swift.Error> = Once<NoKey, Value, Error>

private actor OnceData<Key: Hashable, Value, Error: Swift.Error>: Sendable {
  var tasks = [Key: (Date, Task<Value, Error>)]()

  func insert(key: Key, value: (Date, Task<Value, Error>)) {
    tasks[key] = value
  }

  func delete(key: Key) {
    tasks[key] = nil
  }

  func cancel(key: Key) {
    tasks[key]?.1.cancel()
    tasks[key] = nil
  }

  func cancelAll() {
    for task in tasks.values {
      task.1.cancel()
    }

    tasks = [:]
  }
}

public class Once<Key: Hashable, Value, Error: Swift.Error> {
  public init() {}

  private let data = OnceData<Key, Value, Error>()

  @discardableResult
  public func onceKeepOriginal(key: Key, keepInCache: TimeInterval? = nil, _ handler: @autoclosure () -> Task<Value, Error>) async -> Task<Value, Error> {
    if let task = await data.tasks[key] {
      guard let keepInCache = keepInCache else {
        return task.1
      }

      if abs(task.0.timeIntervalSinceNow) < keepInCache {
        return task.1
      }
    }

    let newTask = handler()
    let date = Date()

    Task.detached(priority: .background) {
      await self.data.insert(key: key, value: (date, newTask))

      do {
        let _ = try await newTask.value
        if keepInCache == nil {
          await self.data.delete(key: key)
        }
      } catch {
        await self.data.delete(key: key)
      }
    }

    return newTask
  }

  @discardableResult
  public func onceKeepOriginal(keepInCache: TimeInterval? = nil, _ handler: @autoclosure () -> Task<Value, Error>) async -> Task<Value, Error> where Key == NoKey {
    return await onceKeepOriginal(key: NoKey(), keepInCache: keepInCache, handler())
  }

  @discardableResult
  public func onceKeepOriginal(key: Key, keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async throws -> Value) async
  -> Task<Value, Error> where Error == Swift.Error
  {
    await onceKeepOriginal(key: key, keepInCache: keepInCache, Task {
      try await handler()
    })
  }

  @discardableResult
  public func onceKeepOriginal(keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async throws -> Value) async
  -> Task<Value, Error> where Error == Swift.Error, Key == NoKey
  {
    return await onceKeepOriginal(key: NoKey(), keepInCache: keepInCache, handler)
  }

  @discardableResult
  public func onceKeepOriginal(key: Key, keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never
  {
    await onceKeepOriginal(key: key, keepInCache: keepInCache, Task {
      await handler()
    })
  }

  @discardableResult
  public func onceKeepOriginal(keepInCache: TimeInterval? = nil, _ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never, Key == NoKey
  {
    await onceKeepOriginal(key: NoKey(), keepInCache: keepInCache, handler)
  }

  @discardableResult
  public func onceCancelOriginal(key: Key, _ handler: @autoclosure () -> Task<Value, Error>) async -> Task<Value, Error> {
    await data.cancel(key: key)

    let newTask = handler()
    await self.data.insert(key: key, value: (Date(), newTask))

    return newTask
  }

  @discardableResult
  public func onceCancelOriginal(_ handler: @autoclosure () -> Task<Value, Error>) async -> Task<Value, Error> where Key == NoKey {
    return await onceCancelOriginal(key: NoKey(), handler())
  }

  @discardableResult
  public func onceCancelOriginal(
    key: Key, _ handler: @escaping @Sendable () async throws -> Value
  ) async -> Task<Value, Error> where Error == Swift.Error
  {
    await onceCancelOriginal(key: key,Task {
      try await handler()
    })
  }

  @discardableResult
  public func onceCancelOriginal(
    _ handler: @escaping @Sendable () async throws -> Value
  ) async -> Task<Value, Error> where Error == Swift.Error, Key == NoKey
  {
    await onceCancelOriginal(key: NoKey(), handler)
  }

  @discardableResult
  public func onceCancelOriginal(key: Key, _ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never
  {
    await onceCancelOriginal(key: key, Task {
      let handler = handler
      return await handler()
    })
  }

  @discardableResult
  public func onceCancelOriginal(_ handler: @escaping @Sendable () async -> Value) async
  -> Task<Value, Error> where Error == Never, Key == NoKey
  {
    await onceCancelOriginal(key: NoKey(), handler)
  }
}

// MARK: Cancellation

extension Once {

  public func cancel(key: Key) async {
    await data.cancel(key: key)
  }

  public func cancelAllAndForget() {
    Task {
      await cancelAll()
    }
  }

  public func cancelAll() async {
    await data.cancelAll()
  }

  public func cancel() async where Key == NoKey {
    await cancel(key: NoKey())
  }
}

// MARK: onceOnlyIfNeeded

extension Once {
  public func onceOnlyIfNeeded(key: Key, _ handler: @autoclosure () -> Task<Value, Error>) async throws -> Value? {
    if await data.tasks[key] != nil {
      return nil
    }

    return try await onceKeepOriginal(key: key, handler()).value
  }

  public func onceOnlyIfNeeded(_ handler: @autoclosure () -> Task<Value, Error>) async -> Value? where Error == Never, Key == NoKey {
    if await data.tasks[NoKey()] != nil {
      return nil
    }

    return await onceKeepOriginal(handler()).value
  }

  public func onceOnlyIfNeeded(key: Key, _ handler: @escaping @Sendable () async -> Value) async throws
  -> Value? where Error == Swift.Error
  {
    try await onceOnlyIfNeeded(key: key, Task {
      await handler()
    })
  }

  public func onceOnlyIfNeeded(_ handler: @escaping @Sendable () async -> Value) async
  -> Value? where Error == Never, Key == NoKey
  {
    await onceOnlyIfNeeded(Task {
      await handler()
    })
  }
}
