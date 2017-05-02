//
//  Packet.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 3/24/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal class Packet {

	internal enum Kind: String {
		case handshake
		case callback
		case inspect
		case stream
		case health
		case event
		case state
		case call
		case pong
		case ping
	}

	// MARK: - Header

	internal(set) public var index: Int
	internal(set) public var kind: Kind
	internal(set) public var resourceIdentifier: String?

	// MARK: - Payload

	internal(set) public var payloadIdentifier: String?
	internal(set) public var payload: Value?

	// MARK: - Lifecycle

	internal init(withIndex index: Int, kind: Kind, resourceIdentifier: String? = nil, payloadIdentifier: String? = nil, payload: Value? = nil) {
		self.index = index
		self.kind = kind
		self.resourceIdentifier = resourceIdentifier
		self.payloadIdentifier = payloadIdentifier
		self.payload = payload
	}

	internal init?(withObject object: Any) {
		guard let packet = object as? [String:Any] else {
			return nil
		}
		guard let kind = packet.keys.flatMap({ Kind(rawValue: $0) }).first else {
			return nil
		}
		guard let header = packet[kind.rawValue] as? [Any],
		      let index = header[safe: 0] as? Int else {
			return nil
		}
		let payload = packet.first {
			$0.key != kind.rawValue
		}
		self.index = index
		self.kind = kind
		self.resourceIdentifier = header[safe: 1] as? String
		self.payloadIdentifier = payload?.key
		self.payload = payload?.value
	}

}
