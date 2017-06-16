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
		guard let applicationName = connection.sessionData.applicationName else {
			// Disconnect with error here
			return
		}
		let onHandshakePerformed: Callback = { response, error in
			if error != nil {
				// Disconnect with error here
			} else if let sessionId = response?[safe: 0] as? String {
				connection.sessionData.sessionId = sessionId
				connection.delegate?.connectionDidConnect(connection)
			}
		}
		if let credentials = connection.sessionData.credentials {
			connection.handshake(applicationName, credentials, onHandshakePerformed)
		} else {
			connection.handshake(applicationName, onHandshakePerformed)
		}
	}

	func transport(_ transport: Transport, didDisconnectWithError error: Error?) {
		guard let connection = self.connection else {
			return
		}
		connection.delegate?.connection(connection, didDisconnectWithError: error)
	}

	func transport(_ transport: Transport, didReceiveData data: Data) {
		guard let connection = self.connection else {
			return
		}
		let packets = connection.chunks.add(chunk: data)
		connection.process(packets)
	}

}
