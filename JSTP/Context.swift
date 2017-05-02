//
//  Context.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

import JavaScriptCore

internal class Context {

	internal static let shared: Context = Context()

	private let context: JSContext!
	private let packet: JSValue!
	private let stringify: JSValue!

	private init() {
		let path = Bundle(for: Context.self).path(forResource: "Common", ofType: "js")!
		let text = try? String(contentsOfFile: path)

		context = JSContext()
		context.exceptionHandler = { context, exception in
			let exceptionDescription = String(describing: exception)
			print(exceptionDescription)
		}
		context.evaluateScript(text)

		stringify = context.objectForKeyedSubscript("stringify")
		packet = context.objectForKeyedSubscript("Packet")
	}

	// MARK: Methods

	internal func stringify(_ packet: Packet) -> String {
		let packetValue = convertToValue(packet)
		return stringify.call(withArguments: [packetValue]).toString()
	}

	internal func parse(_ string: String) -> [Packet] {
		let packets = context.evaluateScript(string)
		return packets?.toArray().flatMap(Packet.init) ?? []
	}

	private func convertToValue(_ packet: Packet) -> JSValue {
		let args = [packet.kind.rawValue, packet.index, packet.resourceIdentifier as Value, packet.payloadIdentifier as Value, packet.payload as Value] as Values
		return self.packet.construct(withArguments: args)
	}

}
