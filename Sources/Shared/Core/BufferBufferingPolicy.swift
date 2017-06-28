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

	internal var countLimit: Int

	internal func buffer(packet: Packet) {
		refineBuffer()
		buffer.append(packet)
	}

	internal func onAcknowledged(packetWithIndex index: Int) {
		self.buffer = buffer.filter { packet in
			return packet.index > index
		}
	}

	private func refineBuffer() {
		guard countLimit > 0 else {
			return
		}
		self.buffer = Array(buffer.suffix(countLimit))
	}

	// MARK: - Lifecycle

	internal init(with countLimit: Int = 0) {
		self.buffer = []
		self.countLimit = countLimit
	}

}
