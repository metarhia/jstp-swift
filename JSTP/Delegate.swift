//
//  Delegate.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 8/31/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

#if CARTHAGE
	import Socket
#endif

internal class TCPSocketDelegateImplementation : TCPSocketDelegate {
	
	fileprivate var connection: Connection!
	
	internal init(_ connection: Connection) {
		self.connection = connection
	}
	
	// MARK: Socket Delegate Methods
	
	internal func socketDidConnect(_ socket: TCPSocket) {
		self.connection.delegate?.connectionDidConnect(self.connection)
	}
	
	internal func socketDidDisconnect(_ socket: TCPSocket) {
		connection.delegate?.connectionDidDisconnect(connection)
	}
	
	internal func socket(_ socket: TCPSocket, didFailWithError error: NSError) {
		connection.delegate?.connection(connection, didFailWithError: error)
	}
	
	internal func socket(_ socket: TCPSocket, didReceiveData data: Data) {
		guard let packets = connection.chunks.add(data) else {
			return
		}
		connection.process(packets)
	}
	
}
