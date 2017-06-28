//
//  PacketsBufferingPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/9/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

internal protocol BufferingPolicy {

	var buffer: [Packet] { get }

	func buffer(packet: Packet)

	func onAcknowledged(packetWithIndex index: Int)

}
