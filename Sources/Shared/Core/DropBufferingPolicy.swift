//
//  DropBufferingPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/9/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

internal class DropBufferingPolicy: BufferingPolicy {

	internal lazy var buffer: [Packet] = []

	internal func buffer(packet: Packet) {
		return
	}

}
