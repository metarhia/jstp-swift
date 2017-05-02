//
//  Configuration.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 4/4/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

public class Credentials {

	public let login: String
	public let password: String

	// MARK: - Initializers

	public init(with login: String, _ password: String) {
		self.login = login
		self.password = password
	}

}

public class Configuration {

	/// Security property indicating the security level of the target stream.
	internal(set) public var secure: Bool

	/// The host this connection be connected to.
	internal(set) public var host: String

	/// The port this connection to be connected on.
	internal(set) public var port: Int

	/// The credentials the user may use to authenticate
	internal(set) public var credentials: Credentials?

	/// Application Name
	internal(set) public var applicationName: String

	// MARK: - Initializers

	public init(host: String, _ port: Int, _ secure: Bool = true, _ applicationName: String, _ credentials: Credentials? = nil) {
		self.host = host
		self.port = port
		self.secure = secure
		self.applicationName = applicationName
		self.credentials = credentials
	}

}
