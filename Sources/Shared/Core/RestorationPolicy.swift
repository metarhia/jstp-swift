//
//  RestorationPolicy.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/22/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation
import UIKit

public class RestorationPolicy {

	internal var bufferingPolicy: BufferingPolicy

	/// Called when transport signaled that it has been connected. You must perform handshake and call specific completion handler depending on the result of the operation.
	///
	/// The default implementation does nothing.
	///
	/// - Warning: Call only one completion handler.
	///
	/// - Parameters:
	///   - connection: Connection instance to work with
	///   - success: The completion handler to call in case of success
	///   - failure: The completion handler to call in case some error occureed. This completion handler takes the following parameters:
	///   - error: An error object that indicates why the operation failed
	internal func onTransportAvailable(connection: Connection, success succeed: @escaping () -> Void, failure fail: @escaping (_ error: Error) -> Void) {

	}

	// MARK: - Lifecycle

	/// The designated initializer. The default implementation does nothing.
	internal init(with bufferingPolicy: BufferingPolicy) {
		self.bufferingPolicy = bufferingPolicy
	}

}
