//
//  File.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/11/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation
import Socket

public class TCPTransport: Transport {

	// swiftlint:disable weak_delegate
	private var socket: TCPSocket
	private var socketDelegate: TCPSocketDelegate?

	// MARK: - Configuration

	// swiftlint:enable weak_delegate
	public weak var delegate: TransportDelegate?

	/// Transport uses the standard delegate paradigm and executes all delegate callbacks on a given
	/// delegate dispatch queue.
	public var delegateQueue: DispatchQueue {
		get {
			return socket.delegateQueue
		}
		set {
			socket.delegateQueue = newValue
		}
	}

	// MARK: - Diagnostics

	/// Returns the state of transport.
	///
	/// A disconnected transport may be recycled.
	/// That is, it can be used again for connecting.
	///
	/// If a transport is in the process of connecting, it may be neither disconnected nor connected.
	public var state: State {
		switch self.socket.status {
			case .opening:
				return .connecting
			case .opened:
				return .connected
			case .closed(let error):
				return .disconnected(error)
		}
	}

	// MARK: - Lifecycle

	/// Creates transport with given parameters.
	///
	/// - Parameters:
	///   - host: The host this transport be connected to.
	///   - port: The port this transport to be connected on.
	///   - secure: Security property indicating the security level of the target stream.
	///   - delegate: A transport delegate object that handles transport-related events.
	///   - delegateQueue: A queue for scheduling the delegate calls. The queue should be a serial queue, in order to ensure the correct ordering of callbacks.
	public init(with host: String, port: Int, secure: Bool = true, delegate: TransportDelegate? = nil, delegateQueue: DispatchQueue = .main) {
		self.delegate = delegate
		self.socket = TCPSocket(with: host, port: port, security: secure ? .negitiated(validates: true) : .none, delegateQueue: delegateQueue)
		self.socketDelegate = SocketDelegate(with: self)
		self.socket.delegate = socketDelegate
	}

	// MARK: - Connecting

	/// Connects the transport.
	///
	/// This method will start a background connect operation and immediately return.
	///
	/// The delegate callbacks are used to notify you when the transport connects, or if the host
	/// was unreachable.
	public func connect() {
		self.socket.connect()
	}

	// MARK: - Disconnecting

	/// Disconnects immediately (synchronously).
	///
	/// If the transport is not already disconnected, an invocation to the
	/// transportDidDisconnect:withError: delegate method will be queued onto the delegateQueue
	/// asynchronously. In other words, the disconnected delegate method will be invoked sometime
	/// shortly after this method returns.
	public func disconnect() {
		self.socket.disconnect()
	}

	// MARK: - Writing

	/// Writes data to the transport. If you pass in zero-length data, this method does nothing.
	public func write(data: Data) {
		self.socket.write(data)
	}

	/// Writes UTF-8 encoded string to the transport.
	public func write(string: String) {
		self.socket.write(string)
	}

}

private class SocketDelegate: TCPSocketDelegate {

	private weak var transport: Transport?

	// MARK: - Lifecycle

	public init(with transport: Transport) {
		self.transport = transport
	}

	// MARK: - TCPSocketDelegate

	public func socketDidConnect(_ socket: Socket.TCPSocket) {
		guard let transport = self.transport else {
			return
		}
		transport.delegate?.transportDidConnect(transport)
	}

	public func socket(_ socket: Socket.TCPSocket, didDisconnectWithError error: Error?) {
		guard let transport = self.transport else {
			return
		}
		transport.delegate?.transport(transport, didDisconnectWithError: error)
	}

	public func socket(_ socket: Socket.TCPSocket, didReceiveData data: Data) {
		guard let transport = self.transport else {
			return
		}
		transport.delegate?.transport(transport, didReceiveData: data)
	}

	public func socket(_ socket: Socket.TCPSocket, didFailWithError error: Error) {
//		guard let transport = self.transport else {
//			return
//		}
//		transport.delegate.transport(transport, didFailWithError error: Error)
	}

}
