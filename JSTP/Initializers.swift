//
//  Initializers.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/1/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation
import Socket

public extension JSTP {
    
   public class func connect(host host: String, port: UInt32) -> Connection {
        
      let socket     = TCPSocket()
      let connection = Connection(socket: socket)
      
      let settings: Socket.Settings = [
         SocketSecurityLevelKey: SocketSecurityLevelNone,
         SocketValidatesCertificateChainKey:false
      ]
        
      socket.delegate = TCPSocketDelegateImplementation(connection)
      socket.connect(host, port: port, settings: settings)
        
      return connection
   }
    
   public class func connect(url _url: String) -> Connection? {
        
      guard let url = NSURL(string: _url) else {
         return nil
      }
        
      guard let host = url.host,
            let port = url.port else {
                
         return nil
      }
        
      return JSTP.connect(host: host, port: port.unsignedIntValue)
   }
    
}

