//
//  Application.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/4/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

public class FunctionCallback {

	private let connection: Connection
	private let packet: Packet

	internal init(connection: Connection, packet: Packet) {
		self.connection = connection
		self.packet = packet
	}

	public func invoke() {
		connection.callback(packet.index, result: [])
	}

	public func invoke(with value: Value) {
		connection.callback(packet.index, result: [value])
	}

}

public class Application {

	public typealias Interface = [String:Function]
	public typealias Function = (FunctionCallback, [Value]) -> Void

	fileprivate var application: [String:Interface]

	internal init() {
		self.application = [:]
	}

}

extension Application: Collection {

	public typealias Iterator = AnyIterator<(String, Interface)>
	public typealias Index = DictionaryIndex<String, Interface>

	public func makeIterator() -> Iterator {
		var iterator = application.makeIterator()
		return Iterator {
			iterator.next()
		}
	}

	public var startIndex: Index {
		return application.startIndex
	}

	public var endIndex: Index {
		return application.endIndex
	}

	public func index(after index: Index) -> Index {
		return application.index(after: index)
	}

	public subscript (position: Index) -> Iterator.Element {
		return application[position]
	}

	public subscript(key: String) -> Interface? {
		get {
			return application[key]
		}
		set {
			application[key] = newValue
		}
	}

}
