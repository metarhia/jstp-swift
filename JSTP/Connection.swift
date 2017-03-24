//
//  Connection.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/7/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

import JavaScriptCore

#if CARTHAGE
	import Socket
#endif

open class Connection {
	
	open var application: Application
	open var delegate: ConnectionDelegate?
	
	internal var callbacks : Callbacks
	internal var socket    : TCPSocket
	internal var chunks    : Chunks
	internal var packetId  : Int
	
	init(socket: TCPSocket) {
		self.application = Application()
		self.delegate    = nil
		
		self.callbacks = Callbacks()
		self.chunks    = Chunks()
		self.socket    = socket
		self.packetId  = 0
		
		self.socket.delegate = TCPSocketDelegateImplementation(self)
	}
	
	// MARK: - Input Packets Processing
	
	private func onHandshakePacket(_ packet: Packet) {
		let data  = packet["ok"   ] as? Values
		let error = packet["error"]
		
		callbacks.removeValue(forKey: 0)?(data, ConnectionError(with: error))
	}
	
	private func onCallbackPacket(_ packet: Packet) {
		let header = packet[PacketKind.callback.rawValue] as! Values
		
		let id     = header[0      ] as! Int
		let data   = packet["ok"   ] as? Values
		let error  = packet["error"]
		
		callbacks.removeValue(forKey: id)?(data, ConnectionError(with: error))
	}
	
	private func onInpectPacket(_ packet: Packet) {
		let header = packet[PacketKind.inspect.rawValue] as! Values
		
		let id   = header[0] as! Int
		let name = header[1] as! String
		
		guard let interface = application[name] else {
			return callback(id, error: ConnectionError(type: .interfaceNotFound))
		}
		
		callback(id, result: Array(interface.keys))
	}
	
	private func onEventPacket(_ packet: Packet) {
		var keys = Array(packet.keys) as! [String]
		
		let header = packet[PacketKind.event.rawValue] as! Values
		let interface = header[1] as! String
		
		keys = keys.filter {
			$0 != PacketKind.event.rawValue
		}
		
		let event     = keys[0]
		let arguments = packet[event] as! Values
		
		delegate?.connection(self, didReceiveEvent: Event(interface: interface, name: event, arguments: arguments))
	}
	
	private func onCallPacket(_ packet: Packet) {
		var keys = Array(packet.keys) as! [String]
		
		let header = packet[PacketKind.call.rawValue] as! Values
		
		let id   = header[0] as! Int
		let name = header[1] as! String
		
		keys = keys.filter { $0 != PacketKind.call.rawValue }
		
		let interface = application[name]
		let method    = keys[0]
		
		let function  = interface?[method]
		let args      = packet    [method] as? Values
		
		if interface == nil { return callback(id, error: ConnectionError(type: .interfaceNotFound)) }
		if function  == nil { return callback(id, error: ConnectionError(type: .methodNotFound   )) }
		
		let result = function!(args!)
		callback(id, result: [result])
	}
	
	private func onPingPacket(_ packet: Packet) {
		let header = packet[PacketKind.ping.rawValue] as! Values
		pong(header[0] as! Int)
	}
	
	internal func process(_ packets: JSValue) {
		let reactions = [
			PacketKind.handshake.rawValue : onHandshakePacket,
			PacketKind.callback.rawValue  : onCallbackPacket,
			PacketKind.inspect.rawValue   : onInpectPacket,
			PacketKind.event.rawValue     : onEventPacket,
			PacketKind.call.rawValue      : onCallPacket,
			PacketKind.ping.rawValue      : onPingPacket
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
	
	fileprivate func packet(_ PacketKind: PacketKind, _ args: Value...) -> JSValue {
		self.packetId += 1
		
		let arguments = [PacketKind.rawValue] + args
		let packet    = Context.shared.packet(arguments)
		
		return packet
	}
	
	// MARK: JavaScript Transfer Protocol
	
	/**
	 *
	 * Send pong packet
	 *
	 *  - Parameter packetId: id of original `ping` packet
	 */
	fileprivate func pong(_ packetId: Int) {
		let packet = self.packet(.pong, packetId)
		self.send(packet)
	}
	
	/**
	 *
	 * Send callback packets
	 *
	 *  - Parameter packetId: id of original `call` packet
	 */
	fileprivate func callback(_ packetId: Int, result: Value) {
		let packet = self.packet(.callback, packetId, "", "ok", result)
		self.send(packet)
	}
	
	/**
	 *
	 * Send callback packets
	 *
	 *  - Parameter packetId: id of original `call` packet
	 */
	fileprivate func callback(_ packetId: Int, error: ConnectionError) {
		let packet = self.packet(.callback, packetId, "", "error", error.asObject)
		self.send(packet)
	}
	
	/**
	 *
	 * Send call packet
	 *
	 *  - Parameter interface:  interface containing required method
	 *  - Parameter method:     method name to be called
	 *  - Parameter parameters: method call parameters
	 *  - Parameter callback:   function
	 */
	open func call(_ interface: String, _ method: String, _ parameters: Values = [], _ callback: Callback? = nil) {
		let packetId = self.packetId
		let packet   = self.packet(.call, packetId, interface, method, parameters)
		
		self.callbacks[packetId] = callback
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
	open func event(_ interface: String, _ event: String, _ parameters: Values = []) {
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
	open func state(_ path: String, _ verb: String, _ value: Value) {
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
	open func handshake(_ name: String, _ login: String, _ password: String, _ callback: Callback? = nil) {
		let packetId = self.packetId
		let packet   = self.packet(.handshake, 0, name, "login" , login, password)
		
		self.callbacks[packetId] = callback
		self.send(packet)
	}
	
	/**
	 *
	 * Send handshake packet
	 *
	 *  - Parameter name:     application name
	 *  - Parameter callback: function callback
	 */
	open func handshake(_ name: String, _ callback: Callback? = nil) {
		let packetId = self.packetId
		let packet   = self.packet(.handshake, 0, name)
		
		self.callbacks[packetId] = callback
		self.send(packet)
	}

}
