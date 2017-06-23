//
//  ConnectionState.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/27/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

extension Connection {

	public enum State {
		case connected
		case connecting
		case disconnected(Error?)
		case disconnecting
	}

}
