//
//  ConnectionDelegate.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 3/24/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

public protocol ConnectionDelegate: class {

	/// Called when a connection receives remote event.
	///
	/// - Parameters:
	///   - connection: Connection instance which received event.
	///   - event: Object holding information about the event.
	func connection(_ connection: Connection, didReceiveEvent event: Event)

	/// Called in case of non-critical errors occur in connection.
	///
	/// - Parameters:
	///   - connection: Connection instance where error occurred.
	///   - error: An object representing an error.
	func connection(_ connection: Connection, didFailWithError error: Error)

	/// Called when a connection disconnects with or without error.
	///
	/// - Parameters:
	///   - connection: Connection instance.
	///   - error: An optional object representing an error.
	func connection(_ connection: Connection, didDisconnectWithError error: Error?)

	/// Called when a connection connects and is ready to work.
	///
	/// - Parameters:
	///   - connection: Connection instance.
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

	public func connection(_ connection: Connection, didDisconnectWithError error: Error?) {
		// DO NOTHING
	}

	public func connectionDidConnect(_ connection: Connection) {
		// DO NOTHING
	}

}
