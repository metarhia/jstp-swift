//
//  Errors.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/25/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

public class ConnectionError: Error, LocalizedError {
	
	public typealias Code = ConnectionErrorCode
	
	public init(code: Code, description: String? = nil) {
		self.code = code
		self.errorDescription = description ?? ConnectionError.defaultMessages[code.rawValue]
	}
	
	public var code: Code
	public var errorDescription: String?
	
	internal var asObject: AnyObject {
		return ["code": code.rawValue, "message": localizedDescription] as AnyObject
	}
	
	internal static func withObject(_ object: Any?) -> ConnectionError? {
		guard let data = object  as? [Any],
		      let code = data[0] as? Int,
		      let errorCode = Code(rawValue: code) else {
			return nil
		}
		return ConnectionError(code: errorCode, description: data[safe: 1] as? String)
	}
	
	// MARK: -
	
	private static let defaultMessages = [
		10: "Application not found",
		11: "Authentication failed",
		12: "Interface not found",
		13: "Incompatible interface",
		14: "Method not found",
		15: "Not a server",
		16: "Internal API error",
		17: "Invalid signature"
	]
	
}

public enum ConnectionErrorCode: Int {
	case appNotFound = 10
	case authFailed = 11
	case interfaceNotFound = 12
	case interfaceIncompatible = 13
	case methodNotFound = 14
	case notSerever = 15
	case internalError = 16
}
