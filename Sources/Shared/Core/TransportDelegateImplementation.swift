//
//  Delegate.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 8/31/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

internal class TransportDelegateImplementation: TransportDelegate {

	private weak var connection: Connection?

	internal init(with connection: Connection) {
		self.connection = connection
	}

	// MARK: Socket Delegate Methods

	func transportDidConnect(_ transport: Transport) {
		guard let connection = self.connection else {
			return
		}
		connection.delegate?.connectionDidConnect(connection)
	}

	func transport(_ transport: Transport, didDisconnectWithError error: Error?) {
		guard let connection = self.connection else {
			return
		}
		connection.delegate?.connectionDidDisconnect(connection)
	}

	func transport(_ transport: Transport, didReceiveData data: Data) {
		guard let connection = self.connection else {
			return
		}
		let packets = connection.chunks.add(chunk: data)
		connection.process(packets)
	}

}
