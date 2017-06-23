//
//  ConnectionState.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/27/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

extension Connection {

	/// Denotes possible `Connection` states.
	public enum State {

		/// Connection is established and is ready for use.
		case connected

		/// Connection is establishing.
		case connecting

		/// Connection is disconnected with optional error.
		case disconnected(Error?)

		/// Connection is in the process of disconnecting.
		case disconnecting
	}

}
