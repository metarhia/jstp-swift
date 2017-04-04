//
//  Application.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/4/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

public class FunctionCallback {
	
	private let application: Application
	private let packet: Packet
	
	internal init(withApplication application: Application, packet: Packet) {
		self.application = application
		self.packet = packet
	}
	
	public func invoke() {
		application.connection.callback(packet.index, result: [])
	}
	
	public func invoke(with value: Value) {
		application.connection.callback(packet.index, result: [value])
	}
	
}

public class Application {
	
	public typealias Interface = [String:Function]
	public typealias Function = (FunctionCallback, Values) -> Void
	
	fileprivate let connection: Connection
	fileprivate var application: [String:Interface]
	
	internal init(withConnection connection: Connection) {
		self.connection = connection
		self.application = [:]
	}
	
	internal func callback(withPacket packet: Packet) -> FunctionCallback {
		return FunctionCallback(withApplication: self, packet: packet)
	}
	
}

extension Application: Collection {
	
	public typealias Iterator = AnyIterator<(String,Interface)>
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
 
	public func index(after i: Index) -> Index {
		return application.index(after: i)
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
