//
//  PacketsBufferingPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/9/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

internal protocol BufferingPolicy {

	/// aaa
	var buffer: [Packet] { get }

	/// 
	///
	/// - Parameter packet: aaa
	func buffer(packet: Packet)

	/// aaa
	///
	/// - Parameter index: aaa
	func onAcknowledged(packetWithIndex index: Int)

}
