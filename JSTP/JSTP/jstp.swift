//
//  api.jstp.swift
//  demo.jstp.connection
//
//  Created by Andrew Visotskyy on 7/7/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

// TODO: Add remote errors support
// TODO: Add inspect packet support
// TODO: Refactor input packets processing method
// TODO: Add ability to be a server
// TODO: ?? Split source code to separate files

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

private extension JSContext {
   subscript(key: String) -> JSValue! {
      return self.objectForKeyedSubscript(key)
   }
}

private extension JSValue {
   subscript(key: AnyObject!) -> JSValue {
      return self.objectForKeyedSubscript(key)
   }
}

// -------------------------------------------------------------------
// Java Script Context used to evaluate scripts and to parse input and
// output data
//
// ??? TODO: refactor this in something more reliable

private func createJavaScriptContext() -> JSContext {
   
   let path = NSBundle(forClass: JSTP.self).pathForResource("jstp", ofType: "js")
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

private class Chunks {
   
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

public class Application {
   
   public typealias Function = (object: AnyObject) -> Void
   
   private var methods: [String:[String:Function]]
   
   init() {
      methods = [String:[String:Function]]()
   }
   
   public func registerHandler(interface: String, handler: String, function: Function) {
      
      if var functions = methods[interface] {
         functions[handler] = function
         return
      }
      
      methods[interface] = [handler:function]
   }
   
}

public class Connection: TCPSocketDelegate {

   public typealias Callback  = (response: AnyObject?, error: AnyObject?) -> Void
   public typealias Callbacks = [Int:Callback]

   public let application: Application

   private var callbacks: Callbacks
   private var socket:    TCPSocket
   private var chunks:    Chunks
   private var packetId:  Int
   
   internal init(socket: TCPSocket) {
      
      self.application = Application()
      self.callbacks   = Callbacks()
      self.chunks      = Chunks()
      
      self.socket = socket
      self.packetId = 0
   }
    
   private func process(packets: JSValue) {
      
      let reactions = [
         
         "handshake" : { (object: AnyObject!) -> Void in
            
            let packetId = object["handshake"]!![0] as! Int
            
            if let callback = self.callbacks.removeValueForKey(packetId) {
               callback(response: object["ok"], error: object["error"])
            }
            
         },
         
         "call": { (packet: AnyObject!) -> Void in
            
            let keys = packet.allKeys
            let method: String
            
            if keys[0] as? String == "call" { method = keys[1] as! String }
            else                            { method = keys[0] as! String }
            
            let packetId     = packet["call"]!![0] as! Int
            let interface    = packet["call"]!![1] as! String
            let apiInterface = self.application.methods[interface]
            let args         = packet[method]
            
            if apiInterface == nil {
               self.callback(packetId, "RemoteError.INTERFACE_NOT_FOUND", nil)
               return
            }
            
            let function = apiInterface![method]
            
            if function == nil {
               self.callback(packetId, "RemoteError.METHOD_NOT_FOUND", nil)
               return
            }
            
            self.callback(packetId, nil, [])
            function!(object: args!!)
         },
         
         "callback": { (packet: AnyObject!) -> Void in
            
            let packetId = packet["callback"]!![0] as! Int
            
            if let callback = self.callbacks.removeValueForKey(packetId) {
               callback(response: packet["ok"], error: packet["error"])
            }
            
         },
         
         "event" : { (packet: AnyObject!) -> Void in
         
            let packetId  = packet["event"]!![0] as! Int
            let interface = packet["event"]!![1] as! String
            
            let keys = packet.allKeys
            let eventName: String
            
            if keys[0] as? String == "event" { eventName = keys[1] as! String }
            else                             { eventName = keys[0] as! String }
            
            let eventArgs = packet[eventName]
            
            // emit this event here
         },
         
         "inspect": { (packet: AnyObject) -> Void in
            
            let packetId = packet["inspect"]!![0] as? Int
            
            let ifName = packet["inspect"]!![1] as? String
            
            if let iface = self.application.methods[ifName!] {
               
               let keys = Array(iface.keys)
               
               self.callback(packetId!, nil, keys)
            
            }
            else {
               self.callback(packetId!, "RemoteError.INTERFACE_NOT_FOUND.jstpArray", nil)
            }
            
         }
         
      ]
      
      for packet in packets.toObject() as! [AnyObject] {
         for key in packet.allKeys {
            if let reaction = reactions[key as! String] {
               reaction(packet)
               break
            }
         }
      }
      
   }
   
   private func send(data: JSValue) {
      
      let context   = jsContext
      let stringify = context["stringify"]
      
      socket.write(stringify.callWithArguments([data]).toString() + kPacketDelimiter)
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
   public func callback(packetId: Int, _ error: AnyObject?, _ result: AnyObject?) {
      
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
   
   // MARK: Socket Delegate Methods
   // TODO: post events to delegate
   
   public func socketDidConnect(socket: Socket.TCPSocket) {
      print("socketDidConnect \(self)")
   }
   
   public func socketDidDisconnect(socket: Socket.TCPSocket) {
      print("socketDidDisconnect \(self)")
   }
   
   public func socketDidFailWithError(socket: Socket.TCPSocket, error: NSError) {
      print("socketDidFailWithError")
   }
   
   public func socketDidReceiveMessage(socket: Socket.TCPSocket, text: String) {
      
      if let packets = chunks.add(text) {
         self.process(packets)
      }
      
      //print("socketDidReceiveMessage \(text)")
   }
   
}

public extension JSTP {

   public class func connect(host host: String, port: UInt32) -> Connection {
    
      let socket     = TCPSocket()
      let connection = Connection(socket: socket)
    
      socket.delegate = connection
      socket.connect(host, port: port)
    
      return connection
   }

}