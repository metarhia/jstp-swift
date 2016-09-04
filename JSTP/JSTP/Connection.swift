//
//  Connection.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/7/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

// TODO: Add remote errors support
// TODO: Add inspect packet support
// TODO: Add ability to be a server
// TODO: ?? Split source code to separate files
// TODO: Profile all

import JavaScriptCore
import Foundation
import Socket

private let kPacketDelimiter       = ",{\u{C}},"
private let kPacketDelimiterLength = kPacketDelimiter.characters.count
private let kHandshakeTimeout      = 3000
private let kChunksFirst           = "["
private let kChunksLast            = "]"

private enum Kind: String {
   case Handshake = "handshake"
   case Callback  = "callback"
   case Stream    = "stream"
   case Health    = "health"
   case Event     = "event"
   case State     = "state"
   case Call      = "call"
}

private extension JSContext { subscript(key: String    ) -> JSValue! { return self.objectForKeyedSubscript(key) } }
private extension JSValue   { subscript(key: AnyObject!) -> JSValue  { return self.objectForKeyedSubscript(key) } }

// -------------------------------------------------------------------
// Java Script Context used to evaluate scripts and to parse input and
// output data
//
// ??? TODO: refactor this in something more reliable

private func createJavaScriptContext() -> JSContext {
   
   let path = NSBundle.mainBundle().pathForResource("Common", ofType: "js")
   let text = try? String(contentsOfFile: path!)
   let ctx  = JSContext()
      
   ctx.exceptionHandler = { context, exception in
      print("JS Error in \(context): \(exception)")
   }
      
   ctx.evaluateScript(text)
   
   return ctx
}

private let jsContext = createJavaScriptContext()

// -------------------------------------------------------------------

public class JSTP { }

private extension JSTP {
   class func parse(data: String) -> JSValue {
      return jsContext.evaluateScript(data)
   }
}

internal class Chunks {
   
   private var buffer: String
   
   init() {
      buffer = kChunksFirst
   }
   
   func add(chunk: String) -> JSValue! {
      
      if chunk.hasSuffix(kPacketDelimiter) {
         
         let index  = chunk.endIndex.advancedBy(-kPacketDelimiterLength + 1)
         let nChunk = chunk.substringToIndex(index)
         var chunks = buffer
         
         chunks.appendContentsOf(nChunk)
         chunks.appendContentsOf(kChunksLast)
         
         buffer = kChunksFirst
         
         let packets: JSValue = JSTP.parse(chunks)
         
         return (packets.isNull || packets.isUndefined) ? nil : packets
      }
      
      return nil
   }
   
}

public class Event {
   
   public let arguments: AnyObject
   public let interface: String
   public let name: String
   
   init(_ interface: String, _ name: String, _ arguments: AnyObject) {
      self.arguments = arguments
      self.interface = interface
      self.name = name
   }
   
}

public protocol ConnectionDelegate {
   
   func connectionDidReceiveEvent    (connection: Connection, event: Event  )
   func connectionDidFail            (connection: Connection, error: NSError)
   func connectionDidPerformHandshake(connection: Connection)
   func connectionDidDisconnect      (connection: Connection)
   func connectionDidConnect         (connection: Connection)
   
}

// MARK: Default implementation for protocol methods

public extension ConnectionDelegate {
   
   func connectionDidReceiveEvent    (connection: Connection, event: Event  ) {}
   func connectionDidFail            (connection: Connection, error: NSError) {}
   func connectionDidPerformHandshake(connection: Connection) {}
   func connectionDidDisconnect      (connection: Connection) {}
   func connectionDidConnect         (connection: Connection) {}
   
}

public class Connection {

   private let queue = dispatch_queue_create("com.metarhia.jstp.connection", nil)
   
   public typealias Callback  = (response: AnyObject?, error: AnyObject?) -> Void
   public typealias Callbacks = [Int:Callback]

   public let application: Application
   public var delegate: ConnectionDelegate?

   internal var callbacks: Callbacks
   internal var socket:    TCPSocket
   internal var chunks:    Chunks
   internal var packetId:  Int
   
   internal init(socket: TCPSocket) {
      
      self.application = Application()
      self.callbacks   = Callbacks()
      self.chunks      = Chunks()
      
      self.delegate = nil
      self.socket = socket
      self.packetId = 0
   }
   
   private func onHandshakePacket(packet: AnyObject) {
      
      let packetId = (packet["handshake"] as! NSArray)[0] as! Int
      
      if let callback = self.callbacks.removeValueForKey(packetId) {
         callback(response: packet["ok"], error: packet["error"])
      }
   }
   
   private func onCallbackPacket(packet: AnyObject) {
      
      let packetId = (packet["callback"] as! NSArray)[0] as! Int
      
      if let callback = self.callbacks.removeValueForKey(packetId) {
         callback(response: packet["ok"], error: packet["error"])
      }
   }
   
   private func onInpectPacket(packet: AnyObject) {
      
      let packetId = (packet["inspect"] as! NSArray)[0] as! Int
      let name     = (packet["inspect"] as! NSArray)[1] as! String
      
      if let interface = application.methods[name] {
         self.callback(packetId, nil, Array(interface.keys))
      }
      else {
         self.callback(packetId, Errors.InterfaceNotFound.raw(), nil)
      }
   }
   
   private func onEventPacket(packet: AnyObject) {
      
      var keys = packet.allKeys as! [String]
      
                 _  = (packet["event"] as! NSArray)[0] as! Int
      let interface = (packet["event"] as! NSArray)[1] as! String
      
      keys = keys.filter({$0 != "event"})
      
      let event     = keys[0]
      let arguments = packet[event]!!
      
      delegate?.connectionDidReceiveEvent(self, event: Event(interface, event, arguments))
   }
   
   private func onCallPacket(packet: AnyObject) {
      
      var keys = packet.allKeys as! [String]
      
      let packetId = (packet["call"] as! NSArray)[0] as! Int
      let name     = (packet["call"] as! NSArray)[1] as! String
      
      keys = keys.filter({$0 != "call"})
      
      let interface = self.application.methods[name]
      let method    = keys[0]
      let arguments = packet[method]!!
      let function  = interface?[method]

      if interface == nil { return callback(packetId, Errors.InterfaceNotFound.raw(), nil) }
      if function  == nil { return callback(packetId, Errors.MethodNotFound.raw(),    nil) }

      callback (packetId, nil, [])
      function?(object: arguments)
   }
   
   internal func process(packets: JSValue) {
      
      typealias Reaction  = AnyObject -> Void
      typealias Reactions = [String:Reaction]
      
      let reactions: Reactions = [
         "handshake" : onHandshakePacket,
         "callback"  : onCallbackPacket,
         "inspect"   : onInpectPacket,
         "event"     : onEventPacket,
         "call"      : onCallPacket
      ]

      for packet in packets.toArray() { for key in packet.allKeys {
         reactions[key as! String]?(packet)
      }}
   }
   
   private func send(data: JSValue) {
      
      let context   = jsContext
      let stringify = context["stringify"]
      
      self.socket.write(stringify.callWithArguments([data]).toString() + kPacketDelimiter)
   }
   
   private func packet(kind: Kind, _ args: AnyObject...) -> JSValue {
      
      let serializer = jsContext["Packet"]
      let packet     = serializer.constructWithArguments([kind.rawValue] + args)
      
      self.packetId += 1
      
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
    *
    */
   public func call(interface: String, _ method: String, _ parameters: AnyObject, _ callback: Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.Call, packetId, interface, method, parameters)
      
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
    *
    */
   public func call(interface: String, _ name: String, _ parameters: AnyObject) {
      let packet = self.packet(.Call, packetId, interface, name, parameters)
      self.send(packet)
   }
   
   /**
    *
    * Send callback packets
    *
    *  - Parameter packetId: id of original `call` packet
    *  - Parameter error:
    *  - Parameter result:
    *
    */
   private func callback(packetId: Int, _ error: AnyObject?, _ result: AnyObject?) {
      
      let packet: JSValue
      
      if error != nil { packet = self.packet(.Callback, packetId, "", "error", error!) }
      else            { packet = self.packet(.Callback, packetId, "", "ok",   result!) }
      
      self.send(packet)
   }

   /**
    *
    * Send event packet
    *
    *  - Parameter interface:  name of interface sending event to
    *  - Parameter event:      name of event
    *  - Parameter parameters: hash or object, event parameters
    *
    */
   public func event(interface: String, _ event: String, _ parameters: AnyObject) {
      let packet = self.packet(.Event, packetId, interface, event, parameters)
      self.send(packet)
   }
   
   /**
    *
    * Send event packet
    *
    *  - Parameter path:  path in data structure to be changed
    *  - Parameter verb:  operation with data inc, dec, let, delete, push, pop, shift, unshift
    *  - Parameter value: delta or new value
    *
    */
   public func state(path: String, _ verb: String, _ value: AnyObject) {
      let packet = self.packet(.State, packetId, path, verb, value)
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
    *
    */
   public func handshake(name: String, _ login: String, _ password: String, _ callback: Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.Handshake, 0, name, login, password)
      
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
    *
    */
   public func handshake(name: String, _ login: String, _ password: String) {
      let packet = self.packet(.Handshake, 0, name, login, password)
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name: application name
    *
    */
   public func handshake(name: String) {
      let packet = self.packet(.Handshake, 0, name)
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name:     application name
    *  - Parameter callback: function callback
    *
    */
   public func handshake(name: String, _ callback: Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.Handshake, 0, name)
      
      self.callbacks[packetId] = callback
      self.send(packet)
   }
   
}

