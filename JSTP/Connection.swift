//
//  Connection.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/7/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

#if CARTHAGE
	import Socket
#endif

open class Connection {
	
	open var application: Application!
	open var delegate: ConnectionDelegate?
	
	internal var callbacks : Callbacks
	internal var socket    : TCPSocket
	internal var chunks    : Chunks
	internal var packetId  : Int
	
	init(socket: TCPSocket) {
		self.delegate = nil
		self.callbacks = Callbacks()
		self.chunks = Chunks()
		self.socket = socket
		self.packetId  = 0
		self.application = Application(withConnection: self)
		self.socket.delegate = TCPSocketDelegateImplementation(self)
	}
	
	// MARK: - Input Packets Processing
	
	private func onHandshakePacket(_ packet: Packet) {
		guard let payloadIdentifier = packet.payloadIdentifier,
		      let payload = packet.payload else {
			let error = ConnectionError(type: .invalidSignature)
			return self.callback(packet.index, error: error)
		}
		let callback = callbacks.removeValue(forKey: packet.index)
		guard payloadIdentifier != "error" else {
			let error = ConnectionError(with: payload)
			callback?(nil, error)
			return
		}
		callback?([payload], nil)
	}
	
	private func onCallbackPacket(_ packet: Packet) {
		guard let payloadIdentifier = packet.payloadIdentifier,
		      let payload = packet.payload as? Values else {
			let error = ConnectionError(type: .invalidSignature)
			return self.callback(packet.index, error: error)
		}
		let callback = callbacks.removeValue(forKey: packet.index)
		guard payloadIdentifier != "error" else {
			let error = ConnectionError(with: payload)
			callback?(nil, error)
			return
		}
		callback?(payload, nil)
	}
	
	private func onInpectPacket(_ packet: Packet) {
		guard let resourceIdentifier = packet.resourceIdentifier else {
			let error = ConnectionError(type: .invalidSignature)
			return self.callback(packet.index, error: error)
		}
		guard let interface = self.application[resourceIdentifier] else {
			let error = ConnectionError(type: .interfaceNotFound)
			return callback(packet.index, error: error)
		}
		let methods = Array(interface.keys)
		callback(packet.index, result: methods)
	}
	
	private func onEventPacket(_ packet: Packet) {
		guard let resourceIdentifier = packet.resourceIdentifier,
		      let payloadIdentifier = packet.payloadIdentifier,
		      let payload = packet.payload as? Values else {
			let error = ConnectionError(type: .invalidSignature)
			return self.callback(packet.index, error: error)
		}
		let event = Event(interface: resourceIdentifier, name: payloadIdentifier, arguments: payload)
		delegate?.connection(self, didReceiveEvent: event)
	}
	
	private func onCallPacket(_ packet: Packet) {
		guard let resourceIdentifier = packet.resourceIdentifier,
		      let payloadIdentifier = packet.payloadIdentifier,
		      let payload = packet.payload as? Values else {
			let error = ConnectionError(type: .invalidSignature)
			return self.callback(packet.index, error: error)
		}
		guard let interface = self.application[resourceIdentifier] else {
			let error = ConnectionError(type: .interfaceNotFound)
			return self.callback(packet.index, error: error)
		}
		guard let method = interface[payloadIdentifier] else {
			let error = ConnectionError(type: .methodNotFound)
			return self.callback(packet.index, error: error)
		}
		let callback = application.callback(withPacket: packet)
		method(callback, payload)
	}
	
	private func onPingPacket(_ packet: Packet) {
		self.pong(packet.index)
	}
	
	internal func process(_ packets: [Packet]) {
		let reactions = [
			Packet.Kind.handshake: onHandshakePacket,
			Packet.Kind.callback: onCallbackPacket,
			Packet.Kind.inspect: onInpectPacket,
			Packet.Kind.event: onEventPacket,
			Packet.Kind.call: onCallPacket,
			Packet.Kind.ping: onPingPacket
		]
		for packet in packets {
			reactions[packet.kind]?(packet)
		}
	}
	
	// MARK: -
	
	private func send(_ packet: Packet) {
		let text = Context.shared.stringify(packet) + kPacketDelimiter
		self.socket.write(text)
	}
	
	private func createPacket(kind: Packet.Kind, resourceIdentifier: String? = nil, payloadIdentifier: String? = nil, payload: Value? = nil) -> Packet {
		let packet = Packet(withIndex: packetId, kind: kind, resourceIdentifier: resourceIdentifier, payloadIdentifier: payloadIdentifier, payload: payload)
		self.packetId = packetId.advanced(by: 1)
		return packet
	}
	
	// MARK: JavaScript Transfer Protocol
	
	/**
	 *
	 * Send pong packet
	 *
	 *  - Parameter packetId: id of original `ping` packet
	 */
	private func pong(_ packetId: Int) {
		let packet = self.createPacket(kind: .pong)
		packet.index = packetId
		self.send(packet)
	}
	
	/**
	 *
	 * Send callback packets
	 *
	 *  - Parameter packetId: id of original `call` packet
	 */
	internal func callback(_ packetId: Int, result: Values) {
		let packet = self.createPacket(kind: .callback, payloadIdentifier: "ok", payload: result)
		packet.index = packetId
		self.send(packet)
	}
	
	/**
	 *
	 * Send callback packets
	 *
	 *  - Parameter packetId: id of original `call` packet
	 */
	internal func callback(_ packetId: Int, error: ConnectionError) {
		let packet = self.createPacket(kind: .callback, payloadIdentifier: "error", payload: error.asObject)
		packet.index = packetId
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
		let packet = self.createPacket(kind: .call, resourceIdentifier: interface, payloadIdentifier: method, payload: parameters)
		self.callbacks[packet.index] = callback
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
		let packet = self.createPacket(kind: .event, resourceIdentifier: interface, payloadIdentifier: event, payload: parameters)
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
		let packet = self.createPacket(kind: .state, resourceIdentifier: path, payloadIdentifier: verb, payload: value)
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
		let packet = self.createPacket(kind: .handshake, resourceIdentifier: name, payloadIdentifier: "login", payload: [login, password])
		self.callbacks[packet.index] = callback
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
		let packet = self.createPacket(kind: .handshake, resourceIdentifier: name)
		self.callbacks[packet.index] = callback
		self.send(packet)
	}

}
