//
//  Transport.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 5/27/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TransportDelegate: class {

	/// Called when a transport connects and is ready for reading and writing.
	func transportDidConnect(_ transport: Transport)

	/// Called when a transport disconnects with or without error.
	///
	/// If you call the disconnect method, and the transport wasn't already disconnected,
	/// then an invocation of this delegate method will be enqueued on the delegateQueue
	/// before the disconnect method returns.
	func transportDidDisconnect(_ transport: Transport, withError error: Error?)

	/// Called when a transport has read in data.
	func transport(_ transport: Transport, didReceiveData data: Data)

}

public protocol Transport: class {

	typealias State = TransportState

	// MARK: - Configuration

	weak var delegate: TransportDelegate? { get set }

	/// Transport uses the standard delegate paradigm and executes all delegate callbacks on a given
	/// delegate dispatch queue.
	var delegateQueue: DispatchQueue { get set }

	// MARK: - Diagnostics

 	/// Returns the state of transport.
 	///
 	/// A disconnected transport may be recycled.
 	/// That is, it can be used again for connecting.
 	///
 	/// If a transport is in the process of connecting, it may be neither disconnected nor connected.
	var state: State { get }

	// MARK: - Connecting

	/// Connects the transport.
	///
	/// This method will start a background connect operation and immediately return.
	///
	/// The delegate callbacks are used to notify you when the transport connects, or if the host
	/// was unreachable.
	func connect()

	// MARK: - Disconnecting

	/// Disconnects immediately (synchronously).
	///
	/// If the transport is not already disconnected, an invocation to the
	/// transportDidDisconnect:withError: delegate method will be queued onto the delegateQueue
	/// asynchronously. In other words, the disconnected delegate method will be invoked sometime
	/// shortly after this method returns.
 	func disconnect()

	// MARK: - Writing

	/// Writes data to the transport. If you pass in zero-length data, this method does nothing.
	func write(data: Data)

}

public enum TransportState {
	case connected
	case connecting
	case disconnected(Error?)
}
