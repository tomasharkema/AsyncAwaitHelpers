//
//  TasksAsyncSequence.swift
//  
//
//  Created by Tomas Harkema on 13/11/2021.
//

import Foundation

public struct TasksAsyncSequence<Value, Error: Swift.Error>: AsyncSequence, AsyncIteratorProtocol {
  public typealias Element = Value

  private(set) var tasks: [() -> Task<Value, Error>]

  public init(tasks: [() -> Task<Value, Error>]) {
    self.tasks = tasks
  }

  public mutating func next() async throws -> Value? {
    guard let element = tasks.popLast() else {
      return nil
    }
    return try await element().value
  }

  public func makeAsyncIterator() -> TasksAsyncSequence<Value, Error> {
    self
  }
}
