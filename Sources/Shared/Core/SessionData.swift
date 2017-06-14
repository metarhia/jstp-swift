//
//  SessionData.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/21/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

public class SessionData {

	/// Application name which was specified during connection
	public internal(set) var applicationName: String?

	/// Current session ID
	public internal(set) var sessionId: String?

	/// Credentials which was specified during connection
	public internal(set) var credentials: Credentials?

	/// The index of the next packet
	internal var nextPacketId: Int

	internal init(applicationName: String? = nil, sessionId: String? = nil, credentials: Credentials? = nil, nextPacketId: Int = 0) {
		self.applicationName = applicationName
		self.sessionId = sessionId
		self.credentials = credentials
		self.nextPacketId = nextPacketId
	}

}
