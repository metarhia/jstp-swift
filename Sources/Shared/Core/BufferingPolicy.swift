//
//  PacketsBufferingPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/9/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

internal protocol BufferingPolicy {

	/// Returns the collection used to store buffered packets.
	var buffer: [Packet] { get }

	/// Called for such a packet that should be buffered when it was attempt to send it. Typical
	/// implementation should store packet in internal buffer or discard it.
	///
	/// - Parameter packet: Object representing packet.
	func buffer(packet: Packet)

	/// Get called after acknowledgement received for packet with given index. Typical implementation
	/// should remove packet which index is less or equal than given.
	///
	/// - Parameter index: Acknowledged packet index.
	func onAcknowledged(packetWithIndex index: Int)

}
