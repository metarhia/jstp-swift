//
//  Initializers.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/1/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation
import Socket

public class JSTP {
   
   public class func connect(host: String, port: Int, secure: Bool = true) -> Connection {
        
      let socket     = TCPSocket()
      let connection = Connection(socket: socket)
      
      var settings = Socket.Settings()
      
      if secure == false {
         settings[SocketSecurityLevel] = SocketSecurityLevelNone
      }
      
      socket.delegate = TCPSocketDelegateImplementation(connection)
      socket.connect(host, port: port, settings: settings)
        
      return connection
   }
    
   public class func connect(url: String, secure: Bool = true) -> Connection? {
        
      guard let url = URL(string: url) else {
         return nil
      }
      
      guard let host = url.host,
            let port = url.port else {
                
         return nil
      }
        
      return JSTP.connect(host: host, port: port, secure: secure)
   }
   
}

