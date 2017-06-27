//
//  BufferBufferingPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/9/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal class BufferBufferingPolicy: BufferingPolicy {

	private(set) internal var buffer: [Packet]

	internal func buffer(packet: Packet) {
		buffer.append(packet)
	}

	// MARK: - Lifecycle

	internal init() {
		self.buffer = []
	}

}
