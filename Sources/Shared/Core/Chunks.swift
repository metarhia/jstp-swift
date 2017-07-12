//
//  Chunks.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

internal class Chunks {

	private var dataBuffer = Data()
	private var stringBuffer = String()

	internal func add(chunk: Data) -> [Packet] {
		dataBuffer.append(chunk)
		guard let string = String.decode(data: &dataBuffer) else {
			return []
		}
		self.stringBuffer.append(string)
		guard let source = Chunks.convertToSource(string: &stringBuffer) else {
			return []
		}
		return Context.shared.parse(source)
	}

	// MARK: -

	private static func convertToSource(string: inout String) -> String? {
		guard let range = string.range(of: kPacketDelimiter, options: .backwards) else {
			return nil
		}
		let source = kChunksFirst + string.substring(to: range.upperBound) + kChunksLast
		string = string.substring(from: range.upperBound)
		return source.replacingOccurrences(of: kPacketDelimiter, with: ",")
	}

}
