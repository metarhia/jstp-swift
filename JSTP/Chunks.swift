//
//  Chunks.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

internal class Chunks {
	
	private var buffer: Data = Data()
	
	internal func add(_ chunk: Data) -> [Packet] {
		buffer.append(chunk)
		guard let source = String(data: buffer, encoding: .utf8), source.hasSuffix(kPacketDelimiter) else {
			return []
		}
		invalidate()
		let chunks = kChunksFirst + source.replacingOccurrences(of: kPacketDelimiter, with: ",") + kChunksLast
		let packets = Context.shared.parse(chunks)
		return packets
	}
	
	internal func invalidate() {
		buffer = Data()
	}
	
}
