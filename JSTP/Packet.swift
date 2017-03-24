//
//  Packet.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 3/24/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal enum PacketKind: String {
	case handshake = "handshake"
	case callback  = "callback"
	case inspect   = "inspect"
	case stream    = "stream"
	case health    = "health"
	case event     = "event"
	case state     = "state"
	case call      = "call"
	case pong      = "pong"
	case ping      = "ping"
}

internal typealias Packet = [AnyHashable:Value]
