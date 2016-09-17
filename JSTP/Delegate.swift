//
//  Delegate.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 8/31/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Socket

internal class TCPSocketDelegateImplementation : TCPSocketDelegate {
    
   fileprivate weak var connection: Connection!
    
   init(_ connection: Connection) {
      self.connection = connection
   }
    
   // MARK: Socket Delegate Methods
   
   internal func socketDidConnect(_ socket: Socket.TCPSocket) {
      connection.delegate?.connectionDidConnect(connection)
   }
    
   internal func socketDidDisconnect(_ socket: Socket.TCPSocket) {
      connection.delegate?.connectionDidDisconnect(connection)
   }
   
   internal func socket(_ socket: TCPSocket, didFailWithError error: NSError) {
      connection.delegate?.connectionDidFail(connection, error: error)
   }
    
   internal func socket(_ socket: TCPSocket, didReceiveMessage text: String) {
      
      guard let packets = connection.chunks.add(text) else {
         return
      }
      
      connection.process(packets)
   }
    
}

