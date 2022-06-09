//
//  AssertMainQueue.swift
//  hm-mm
//
//  Created by Tomas Harkema on 24/11/2020.
//

import Foundation

@inlinable public func assertMainQueue() {
#if DEBUG
  if !Foundation.Thread.current.isMainThread {
    assertionFailure("Should be called from main thread")
  }
#endif
}

@inlinable public func assertNotMainQueue() {
#if DEBUG
  if Foundation.Thread.current.isMainThread {
    assertionFailure("Should not be called from main thread")
  }
#endif
}
