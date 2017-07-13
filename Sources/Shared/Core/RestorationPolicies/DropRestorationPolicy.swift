//
//  DropRestorationPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/27/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public class DropRestorationPolicy: RestorationPolicy {

	internal override func onTransportAvailable(connection: Connection, success succeed: @escaping () -> Void, failure fail: @escaping (Error) -> Void) {
		if let applicationName = connection.sessionData.applicationName {
			connection.handshake(applicationName) { response, error in
				if let error = error {
					fail(error)
				} else {
					connection.sessionData.sessionId = response?[safe: 0] as? String
					succeed()
				}
			}
		} else {
			connection.disconnect(with: nil /* Replace with error */)
		}
	}

	public init() {
		let bufferingPolicy = DropBufferingPolicy()
		super.init(with: bufferingPolicy)
	}

}
