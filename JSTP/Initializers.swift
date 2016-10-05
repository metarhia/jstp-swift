//
//  Initializers.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/1/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation
import Socket

public extension Connection {
   
   public convenience init (host: String, port: Int, secure: Bool = true) {
      
      var settings = Socket.Settings()
      
      if secure == false {
         settings[SocketSecurityLevel] = SocketSecurityLevelNone
      }
      
      let socket = TCPSocket (host: host, port: port, settings: settings)

      self.init(socket: socket)
   }
   
   public convenience init? (url: String, secure: Bool = true) {
    
      guard let url = URL(string: url) else {
         return nil
      }
      
      guard let host = url.host,
            let port = url.port else {
            
         return nil
      }
      
      self.init(host: host, port: port, secure: secure)
   }
   
   public func connect() {
      self.socket.connect()
   }
   
}

