//
//  ConcurrencyLimiter.swift
//  
//
//  Created by Tomas Harkema on 11/11/2021.
//

import Foundation

public class ConcurrencyLimiter {
  private var hasLock = false
  let limit = 4
  private let data = ConcurrencyLimiterData()

  func obtain() async -> () -> () {
    if await data.count > limit {
      let task = Task {
        await Task.yield()
        try await Task.sleep(nanoseconds: 1200 * 100_000_000)
      }
      await data.append(task: task)
      await Task.yield()
      _ = await task.result
    }

    await data.increase()

    return {
      Task {
        await self.data.decreaseAndPop()?.cancel()
      }
    }
  }
}

actor ConcurrencyLimiterData {
  var count = 0
  var tasks: [Task<(), Error>] = []

  func append(task: Task<(), Error>) {
    tasks.append(task)
  }

  func increase() {
    count += 1
  }

  func decreaseAndPop() -> Task<(), Error>? {
    count -= 1
    return tasks.popLast()
  }
}
