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

	// MARK: Factory methods

	public static var `default`: Configuration {
		return Configuration()
	}

}
