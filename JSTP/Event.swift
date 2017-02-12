//
//  Event.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

open class Event {
	
	open let arguments: AnyObject
	open let interface: String
	open let name: String
	
	internal init(_ interface: String, _ name: String, _ arguments: AnyObject) {
		self.arguments = arguments
		self.interface = interface
		self.name = name
	}
	
}
