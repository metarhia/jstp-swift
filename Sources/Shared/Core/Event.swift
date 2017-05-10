//
//  Event.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

public class Event {

	public let arguments: [Value]
	public let interface: String
	public let name: String

	public init(interface: String, name: String, arguments: [Value]) {
		self.arguments = arguments
		self.interface = interface
		self.name = name
	}

}
