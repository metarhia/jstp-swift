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
   
   let path = Bundle(for: Connection.self).path(forResource: "Common", ofType: "js")
   let text = try? String(contentsOfFile: path!)
   let ctx  = JSContext()
      
   ctx?.exceptionHandler = { context, exception in
      print("JS Error in \(context): \(exception)")
   }
   
   _ = ctx?.evaluateScript(text)
   
   return ctx!
}

private let jsContext = createJavaScriptContext()

// -------------------------------------------------------------------

open class JSTP { }

private extension JSTP {
   class func parse(_ data: String) -> JSValue {
      return jsContext.evaluateScript(data)
   }
}

internal class Chunks {
   
   fileprivate var buffer: String
   
   init() {
      buffer = kChunksFirst
   }
   
   func add(_ chunk: String) -> JSValue! {
      
      if chunk.hasSuffix(kPacketDelimiter) {
         
         let index  = chunk.characters.index(chunk.endIndex, offsetBy: -kPacketDelimiterLength + 1)
         let nChunk = chunk.substring(to: index)
         var chunks = buffer
         
         chunks.append(nChunk)
         chunks.append(kChunksLast)
         
         buffer = kChunksFirst
         
         let packets: JSValue = JSTP.parse(chunks)
         
         return (packets.isNull || packets.isUndefined) ? nil : packets
      }
      
      return nil
   }
   
}

open class Event {
   
   open let arguments: AnyObject
   open let interface: String
   open let name: String
   
   init(_ interface: String, _ name: String, _ arguments: AnyObject) {
      self.arguments = arguments
      self.interface = interface
      self.name = name
   }
   
}

public protocol ConnectionDelegate {
   
   func connectionDidReceiveEvent    (_ connection: Connection, event: Event  )
   func connectionDidFail            (_ connection: Connection, error: NSError)
   func connectionDidPerformHandshake(_ connection: Connection)
   func connectionDidDisconnect      (_ connection: Connection)
   func connectionDidConnect         (_ connection: Connection)
   
}

// MARK: Default implementation for protocol methods

public extension ConnectionDelegate {
   
   func connectionDidReceiveEvent    (_ connection: Connection, event: Event  ) {}
   func connectionDidFail            (_ connection: Connection, error: NSError) {}
   func connectionDidPerformHandshake(_ connection: Connection) {}
   func connectionDidDisconnect      (_ connection: Connection) {}
   func connectionDidConnect         (_ connection: Connection) {}
   
}

open class Connection {

   fileprivate let queue = DispatchQueue(label: "com.metarhia.jstp.connection", attributes: [])
   
   public typealias Callback  = (_ response: AnyObject?, _ error: AnyObject?) -> Void
   public typealias Callbacks = [Int:Callback]

   open let application: Application
   open var delegate: ConnectionDelegate?

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
   
   fileprivate func onHandshakePacket(_ packet: AnyObject) {
      
      let packetId = (packet["handshake"] as! NSArray)[0] as! Int
      
      if let callback = self.callbacks.removeValue(forKey: packetId) {
         callback(packet["ok"] as AnyObject, packet["error"] as AnyObject)
      }
   }
   
   fileprivate func onCallbackPacket(_ packet: AnyObject) {
      
      let packetId = (packet["callback"] as! NSArray)[0] as! Int
      
      if let callback = self.callbacks.removeValue(forKey: packetId) {
         callback(packet["ok"] as AnyObject, packet["error"] as AnyObject)
      }
   }
   
   fileprivate func onInpectPacket(_ packet: AnyObject) {
      
      let packetId = (packet["inspect"] as! NSArray)[0] as! Int
      let name     = (packet["inspect"] as! NSArray)[1] as! String
      
      if let interface = application.methods[name] {
         self.callback(packetId, nil, Array(interface.keys) as AnyObject?)
      }
      else {
         self.callback(packetId, Errors.InterfaceNotFound.raw(), nil)
      }
   }
   
   fileprivate func onEventPacket(_ packet: AnyObject) {
      
      var keys = packet.allKeys as! [String]
      
                 _  = (packet["event"] as! NSArray)[0] as! Int
      let interface = (packet["event"] as! NSArray)[1] as! String
      
      keys = keys.filter({$0 != "event"})
      
      let event     = keys[0]
      let arguments = packet[event]!!
      
      delegate?.connectionDidReceiveEvent(self, event: Event(interface, event, arguments as AnyObject))
   }
   
   fileprivate func onCallPacket(_ packet: AnyObject) {
      
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

      callback (packetId, nil, [] as AnyObject)
      function?(arguments as AnyObject)
   }
   
   internal func process(_ packets: JSValue) {
      
      typealias Reaction  = (AnyObject) -> Void
      typealias Reactions = [String:Reaction]
      
      let reactions: Reactions = [
         "handshake" : onHandshakePacket,
         "callback"  : onCallbackPacket,
         "inspect"   : onInpectPacket,
         "event"     : onEventPacket,
         "call"      : onCallPacket
      ]

      for packet in packets.toArray() { for key in (packet as AnyObject).allKeys {
         reactions[key as! String]?(packet as AnyObject)
      }}
   }
   
   fileprivate func send(_ data: JSValue) {
      
      let context   = jsContext
      let stringify = context["stringify"]!
      
      self.socket.write(stringify.call(withArguments: [data]).toString() + kPacketDelimiter)
   }
   
   fileprivate func packet(_ kind: Kind, _ args: Any...) -> JSValue {
      
      let serializer = jsContext["Packet"]!
      let packet     = serializer.construct(withArguments: [kind.rawValue] + args)
      
      self.packetId += 1
      
      return packet!
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
   open func call(_ interface: String, _ method: String, _ parameters: AnyObject, _ callback: @escaping Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.Call, packetId as AnyObject, interface as AnyObject, method as AnyObject, parameters)
      
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
   open func call(_ interface: String, _ name: String, _ parameters: AnyObject) {
      let packet = self.packet(.Call, packetId as AnyObject, interface as AnyObject, name as AnyObject, parameters)
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
   fileprivate func callback(_ packetId: Int, _ error: AnyObject?, _ result: AnyObject?) {
      
      let packet: JSValue
      
      if error != nil { packet = self.packet(.Callback, packetId as AnyObject, "" as AnyObject, "error" as AnyObject, error!) }
      else            { packet = self.packet(.Callback, packetId as AnyObject, "" as AnyObject, "ok" as AnyObject,   result!) }
      
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
   open func event(_ interface: String, _ event: String, _ parameters: AnyObject) {
      let packet = self.packet(.Event, packetId as AnyObject, interface as AnyObject, event as AnyObject, parameters)
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
   open func state(_ path: String, _ verb: String, _ value: AnyObject) {
      let packet = self.packet(.State, packetId as AnyObject, path as AnyObject, verb as AnyObject, value)
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
   open func handshake(_ name: String, _ login: String, _ password: String, _ callback: @escaping Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.Handshake, 0 as AnyObject, name as AnyObject, login as AnyObject, password as AnyObject)
      
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
   open func handshake(_ name: String, _ login: String, _ password: String) {
      let packet = self.packet(.Handshake, 0 as AnyObject, name as AnyObject, login as AnyObject, password as AnyObject)
      self.send(packet)
   }
   
   /**
    *
    * Send handshake packet
    *
    *  - Parameter name: application name
    *
    */
   open func handshake(_ name: String) {
      let packet = self.packet(.Handshake, 0 as AnyObject, name as AnyObject)
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
   open func handshake(_ name: String, _ callback: @escaping Callback) {
      
      let packetId = self.packetId
      let packet   = self.packet(.Handshake, 0 as AnyObject, name as AnyObject)
      
      self.callbacks[packetId] = callback
      self.send(packet)
   }
   
}

