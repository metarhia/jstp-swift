//
//  ConnectionDelegate.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 3/24/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

public protocol ConnectionDelegate {

	func connection(_ connection: Connection, didReceiveEvent event: Event)

	func connection(_ connection: Connection, didFailWithError error: Error)

	func connectionDidDisconnect(_ connection: Connection)

	func connectionDidConnect(_ connection: Connection)

}

// MARK: Default implementation for protocol

public extension ConnectionDelegate {

	public func connection(_ connection: Connection, didReceiveEvent event: Event) {
		// DO NOTHING
	}

	public func connection(_ connection: Connection, didFailWithError error: Error) {
		// DO NOTHING
	}

	public func connectionDidDisconnect(_ connection: Connection) {
		// DO NOTHING
	}

	public func connectionDidConnect(_ connection: Connection) {
		// DO NOTHING
	}

}
