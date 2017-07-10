//
//  BufferBufferingPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/9/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

internal class BufferBufferingPolicy: BufferingPolicy {

	private(set) internal var buffer: [Packet]

	/// The maximum number of objects the buffer should hold.
	///
	/// If 0 or less, there is no count limit. The default value is 0.
	///
	/// This is not a strict limit — if the buffer goes over the limit, an object in the buffer could
	/// be evicted instantly, later, or possibly never, depending on the implementation details of
	/// the buffer.
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

	/// Refines buffer due to the maximum number of objects the buffer should hold.
	private func refineBuffer() {
		guard countLimit > 0 else {
			return
		}
		self.buffer = Array(buffer.suffix(countLimit))
	}

	// MARK: - Lifecycle

	/// Returns a `BufferingPolicy` object initialized by using a given `countLimit` or default value
	/// which is equal to 0.
	///
	/// - Parameter countLimit: The maximum number of objects the buffer should hold.
	internal init(with countLimit: Int = 0) {
		self.buffer = []
		self.countLimit = countLimit
	}

}
