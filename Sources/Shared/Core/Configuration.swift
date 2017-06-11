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

	/// The credentials the user may use to authenticate
	internal(set) public var credentials: Credentials?

	/// Application Name
	internal(set) public var applicationName: String

	// MARK: - Initializers

	public init(_ applicationName: String, _ credentials: Credentials? = nil) {
		self.applicationName = applicationName
		self.credentials = credentials
	}

}
