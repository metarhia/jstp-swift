//
//  Transport.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 5/27/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public protocol TransportDelegate: class {

	func transportDidConnect(_ transport: Transport)

	func transportDidDisconnect(_ transport: Transport, withError error: Error)

	func transport(_ transport: Transport, didReceiveData data: Data)

}

public protocol Transport {

	typealias State = TransportState

	// MARK: - Configuration

	weak var delegate: TransportDelegate? { get set }

	var delegateQueue: DispatchQueue { get set }

	// MARK: - Diagnostics

	var state: State { get }

	// MARK: - Connecting

	func connect()

	// MARK: - Disconnecting

 	func disconnect()

	// MARK: - Writing

	func write(data: Data)

}

public enum TransportState {
	case connected
	case connecting
	case disconnecting
	case disconnected(Error?)
}
