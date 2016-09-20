//
//  Connection.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/7/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

// TODO: Add ability to be a server
// TODO: Profile all
// TODO: Update common.js with latest modifications
// TODO: Add something like event emitter to Connection

import JavaScriptCore
import Socket

fileprivate enum Kind: String {
   
   case handshake = "handshake"
   case callback  = "callback"
   case stream    = "stream"
   case health    = "health"
   case event     = "event"
   case state     = "state"
   case call      = "call"
}

public protocol ConnectionDelegate {
   
   func connection(_ connection: Connection, didReceiveEvent  event: Event)
   func connection(_ connection: Connection, didFailWithError error: Error)
   
   func connectionDidDisconnect(_ connection: Connection)
   func connectionDidConnect   (_ connection: Connection)
   
}

// MARK: Default implementation for protocol methods

public extension ConnectionDelegate {
   
   func connection(_ connection: Connection, didReceiveEvent  event: Event) {}
   func connection(_ connection: Connection, didFailWithError error: Error) {}
   
   func connectionDidDisconnect(_ connection: Connection) {}
   func connectionDidConnect   (_ connection: Connection) {}
   
}

open class Connection {

   open var application : Application
   open var delegate    : ConnectionDelegate?

   var callbacks : Callbacks
   var socket    : TCPSocket
   var chunks    : Chunks
   var packetId  : Int
   
   init(socket: TCPSocket) {
      
      self.application = Application()
      self.delegate    = nil
      
      self.callbacks = Callbacks()
      self.chunks    = Chunks()
      self.socket    = socket
      self.packetId  = 0
   }
   
   // MARK: - Input Packets Processing
   
   private func onHandshakePacket(_ packet: Packet) {

      let data  = packet["ok"   ]
      let error = packet["error"]
      
      callbacks.removeValue(forKey: 0)?(data, Error(error))
   }
   
   private func onCallbackPacket(_ packet: Packet) {
      
      let header = packet["callback"] as! [Any]
      
      let id     = header[0      ] as! Int
      let data   = packet["ok"   ]
      let error  = packet["error"]
      
      callbacks.removeValue(forKey: id)?(data, Error(error))
   }
   
   private func onInpectPacket(_ packet: Packet) {
      
      let header = packet["callback"] as! [Any]
      
      let id   = header[0] as! Int
      let name = header[1] as! String
      
      guard let interface = application[name] else {
         return callback(id, error: Errors.InterfaceNotFound)
      }
      
      callback(id, result: interface.keys)
   }
   
   private func onEventPacket(_ packet: Packet) {
      
      var keys = Array(packet.keys) as! [String]
      
      let header = packet["event"] as! [Any]
      
                 _  = header[0] as! Int
      let interface = header[1] as! String
   
      keys = keys.filter({$0 != "event"})
      
      let event     = keys[0]
      let arguments = packet[event]!
      
      delegate?.connection(self, didReceiveEvent: Event(interface, event, arguments))
   }
   
   private func onCallPacket(_ packet: Packet) {
      
      var keys = Array(packet.keys) as! [String]
      
      let header = packet["call"] as! [Any]
      
      let id   = header[0] as! Int
      let name = header[1] as! String
      
      keys = keys.filter({$0 != "call"})
      
      let interface = application[name]
      let method    = keys[0]
      
      let function  = interface?[method]
      let args      = packet    [method]

      if interface == nil { return callback(id, error: Errors.InterfaceNotFound) }
      if function  == nil { return callback(id, error: Errors.MethodNotFound   ) }
      
      function?(args)
      callback (id, result: [])
   }
   
   internal func process(_ packets: JSValue) {
      
      let reactions = [
         "handshake" : onHandshakePacket,
         "callback"  : onCallbackPacket,
         "inspect"   : onInpectPacket,
         "event"     : onEventPacket,
         "call"      : onCallPacket
      ]
   
      for packet in packets.toArray() {
         
         let packet = packet as! Packet
         let keys   = packet.keys
         
         for case let key as String in keys  {
            reactions[key]?(packet)
         }
      }
   }
   
   // MARK: -
   
   fileprivate func send(_ data: JSValue) {
      
      let context = Context.shared
      let text    = context.stringify(data) + kPacketDelimiter
      
      self.socket.write(text)
   }
   
   fileprivate func packet(_ kind: Kind, _ args: Any...) -> JSValue {
      
      self.packetId += 1
      
      let arguments = [kind.rawValue] + args
      let packet    = Context.shared.packet(arguments)
      
      return packet
   }
   
   // MARK: JavaScript Transfer Protocol
   
   /**
    *
    * Send call packet
    *
    *  - Parameter interface:  interface containing required method
    *  - Parameter method:     method name to be called
    *  - Parameter parameters: method call parameters
    *  - Parameter callback:   function
    */
   open func call(_ interface: String, _ method: String, _ parameters: Any, _ callback: @escaping Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.call, packetId, interface, method, parameters)
      
      self.callbacks[packetId] = callback
      self.send(packet)
   }
   
   /**
    *
    * Send call packet
    *
    *  - Parameter interface:  interface containing required method
    *  - Parameter method:     method name to be called
    *  - Parameter parameters: method call parameters
    */
   open func call(_ interface: String, _ method: String, _ parameters: Any) {
      let packet = self.packet(.call, packetId, interface, method, parameters)
      self.send(packet)
   }

   /**
    *
    * Send callback packets
    *
    *  - Parameter packetId: id of original `call` packet
    */
   fileprivate func callback(_ packetId: Int, result: Any) {
      let packet = self.packet(.callback, packetId, "", "ok", result)
      self.send(packet)
   }
   
   /**
    *
    * Send callback packets
    *
    *  - Parameter packetId: id of original `call` packet
    */
   fileprivate func callback(_ packetId: Int, error: Error) {
      let packet = self.packet(.callback, packetId, "", "error", error.raw())
      self.send(packet)
   }

   /**
    *
    * Send event packet
    *
    *  - Parameter interface:  name of interface sending event to
    *  - Parameter event:      name of event
    *  - Parameter parameters: hash or object, event parameters
    */
   open func event(_ interface: String, _ event: String, _ parameters: Any) {
      let packet = self.packet(.event, packetId, interface, event, parameters)
      self.send(packet)
   }
   
   /**
    *
    * Send event packet
    *
    *  - Parameter path:  path in data structure to be changed
    *  - Parameter verb:  operation with data inc, dec, let, delete, push, pop, shift, unshift
    *  - Parameter value: delta or new value
    */
   open func state(_ path: String, _ verb: String, _ value: Any) {
      let packet = self.packet(.state, packetId, path, verb, value)
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name:     application name
    *  - Parameter login:    user login
    *  - Parameter password: password hash
    *  - Parameter callback: function callback
    */
   open func handshake(_ name: String, _ login: String, _ password: String, _ callback: @escaping Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.handshake, 0, name, login, password)
      
      self.callbacks[packetId] = callback
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name:     application name
    *  - Parameter login:    user login
    *  - Parameter password: password hash
    */
   open func handshake(_ name: String, _ login: String, _ password: String) {
      let packet = self.packet(.handshake, 0, name, login, password)
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name: application name
    */
   open func handshake(_ name: String) {
      let packet = self.packet(.handshake, 0, name)
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name:     application name
    *  - Parameter callback: function callback
    */
   open func handshake(_ name: String, _ callback: @escaping Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.handshake, 0, name)
      
      self.callbacks[packetId] = callback
      self.send(packet)
   }
   
}

/****************************************************/

fileprivate extension JSContext { subscript(key: Any!) -> JSValue! { return objectForKeyedSubscript(key) } }
fileprivate extension JSValue   { subscript(key: Any!) -> JSValue! { return objectForKeyedSubscript(key) } }

