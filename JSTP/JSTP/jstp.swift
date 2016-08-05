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
   
   let path = NSBundle.mainBundle().pathForResource("jstp", ofType: "js")
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
   
   public func register(interface: String, handler: String, function: Function) {
      
      if var functions = methods[interface] {
         functions[handler] = function
         return
      }
      
      methods[interface] = [handler:function]
   }
   
}

public protocol ConnectionDelegate {
   
   func handshakePassedSuccesfully(object: AnyObject)
   
   func errorDidHappend(error: AnyObject)
   
   func someEvent(interface: String, _ event: String, _ arguments: AnyObject)

   func connected(connection: Connection)
   
   func disconnected(connection: Connection)
   
}

// MARK: Provide default implementation protocol methods

public extension ConnectionDelegate {
   
   func handshakePassedSuccesfully(object: AnyObject) {
      
   }
   
   func errorDidHappend(error: AnyObject) {
      
   }
   
   func someEvent(interface: String, _ event: String, _ arguments: AnyObject) {
      
   }
   
   func connected(connection: Connection) {
      
   }
   
   func disconnected(connection: Connection) {
      
   }
   
}

public class Connection {

   private let queue = dispatch_queue_create("com.metarhia.jstp.connection", nil)
   
   public typealias Callback  = (response: AnyObject?, error: AnyObject?) -> Void
   public typealias Callbacks = [Int:Callback]

   public let application: Application
   public var delegate: ConnectionDelegate?

   private var callbacks: Callbacks
   private var socket:    TCPSocket
   private var chunks:    Chunks
   private var packetId:  Int
   
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
         self.callback(packetId, Error.InterfaceNotFound, nil)
      }
   }
   
   private func onEventPacket(packet: AnyObject) {
      
      var keys = packet.allKeys as! [String]
      
                 _  = (packet["event"] as! NSArray)[0] as! Int
      let interface = (packet["event"] as! NSArray)[1] as! String
      
      keys = keys.filter({$0 != "event"})
      
      let event     = keys[0]
      let arguments = packet[event]!!
      
      delegate?.someEvent(interface, event, arguments)
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

      if interface == nil { return callback(packetId, Error.InterfaceNotFound.toArray, nil) }
      if function  == nil { return callback(packetId, Error.MethodNotFound.toArray,    nil) }

      callback (packetId, nil, [])
      function?(object: arguments)
   }
   
   private func process(packets: JSValue) {
      
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
      
      print("socketDidSendMessage" + stringify.callWithArguments([data]).toString() + kPacketDelimiter)
      
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

private class TCPSocketDelegateImplementation : TCPSocketDelegate {
   
   private weak var connection: Connection!
   
   init(_ connection: Connection) {
      self.connection = connection
   }
   
   // MARK: Socket Delegate Methods
   
   private func socketDidConnect(socket: Socket.TCPSocket) {
      print("socketDidConnect")
      connection.delegate?.connected(connection)
   }
   
   private func socketDidDisconnect(socket: Socket.TCPSocket) {
      print("socketDidDisconnect")
      connection.delegate?.disconnected(connection)
   }
   
   private func socketDidFailWithError(socket: Socket.TCPSocket, error: NSError) {
      print("socketDidFailWithError: \(error.localizedDescription)")
   }
   
   private func socketDidReceiveMessage(socket: Socket.TCPSocket, text: String) {
      
      print("socketDidReceiveMessage \(text)")
      
      if let packets = connection.chunks.add(text) {
         connection.process(packets)
      }
      
      
   }
   
}

public extension JSTP {

   public class func connect(host host: String, port: UInt32) -> Connection {
   
      let socket     = TCPSocket()
      let connection = Connection(socket: socket)
    
      let settings: Settings = [
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