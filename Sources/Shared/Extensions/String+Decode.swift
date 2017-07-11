//
//  String+Extension.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 8/8/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

extension String {

	public static func decode(data: inout Data) -> String? {
		var headerPosition = data.count - 1
		while data[headerPosition] & UInt8(0xC0) == UInt8(0x80) {
			headerPosition -= 1
		}
		let header = data[headerPosition]
		guard let length = String.characterBytesCount(for: header) else {
			return nil
		}
		let validCount = headerPosition + length == data.count ? data.count : headerPosition
		let validBytes = data.prefix(upTo: validCount)
		data.removeFirst(validCount)
		return String(bytes: validBytes, encoding: .utf8)
	}

	private static func characterBytesCount(for header: UInt8) -> Int? {
		if header & UInt8(0x80) == UInt8(0) {
			return 1
		} else if header & UInt8(0xE0) == UInt8(0xC0) {
			return 2
		} else if header & UInt8(0xF0) == UInt8(0xE0) {
			return 3
		} else if header & UInt8(0xF8) == UInt8(0xF0) {
			return 4
		} else {
			return nil
		}
	}

}
