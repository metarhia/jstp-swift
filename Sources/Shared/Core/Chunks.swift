//
//  Chunks.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

internal class Chunks {

	private var buffer: Data = Data()

	internal func add(chunk: Data) -> [Packet] {
		buffer.append(chunk)
		guard let source = Chunks.convert(data: buffer) else {
			return []
		}
		invalidate()
		return Context.shared.parse(source)
	}

	internal func invalidate() {
		buffer = Data()
	}

	// MARK: -

	private static func convert(data: Data) -> String? {
		guard let source = String(data: data, encoding: .utf8), source.hasSuffix(kPacketDelimiter) else {
			return nil
		}
		return kChunksFirst + source.replacingOccurrences(of: kPacketDelimiter, with: ",") + kChunksLast
	}

}
