//
//  DictionaryActor.swift
//
//
//  Created by Tomas Harkema on 19/06/2021.
//

public actor DictionaryActor<Key: Hashable, Value> {
  private var dict = [Key: Value]()

  public init() {}

  public func values() -> [Value] {
    Array(dict.values)
  }

  public func insert(_ key: Key, value: Value?) {
    dict[key] = value
  }

  public func get(_ key: Key) -> Value? {
    dict[key]
  }

  public func isEmpty() -> Bool {
    dict.isEmpty
  }
}