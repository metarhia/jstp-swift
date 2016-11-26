//
//  Initializers.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/1/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

#if CARTHAGE
   import Socket
#endif

public extension Connection {
   
   public convenience init (host: String, port: Int, secure: Bool = true) {
      
      var settings = Settings()
      
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
   
   public func reconnect() {
      
      let secure = socket.options.contains { SocketSecurityLevel     == $0 &&
                                             SocketSecurityLevelNone == $1 as! String }
      
      self.reconnect(host: socket.host, port: socket.port, secure: secure)
   }
   
   public func reconnect(host: String, port: Int, secure: Bool = true) {
      
      var settings = Settings()
      
      if secure == false {
         settings[SocketSecurityLevel] = SocketSecurityLevelNone
      }
      
      self.callbacks = Callbacks()
      self.chunks    = Chunks()
      self.packetId  = 0
      
      self.socket = TCPSocket(host: host, port: port, settings: settings)
      
      self.socket.delegate = TCPSocketDelegateImplementation(self)
      self.socket.connect()
   }
   
}

