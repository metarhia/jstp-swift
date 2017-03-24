//
//  Errors.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/25/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

public class ConnectionError: Error, LocalizedError {
	
	public typealias Code = Int
	public typealias ErrorType = ConnectionErrorType
	
	public init(type: ErrorType, description: String? = nil) {
		self.type = type
		self.code = type.rawValue
		self.errorDescription = description ?? ConnectionError.defaultMessages[type.rawValue]
	}
	
	public init(code: Int, description: String? = nil) {
		self.code = code
		self.type = ErrorType(rawValue: code)
		self.errorDescription = description ?? ConnectionError.defaultMessages[code]
	}
	
	public var code: Code
	public var type: ErrorType?
	public var errorDescription: String?
	
	internal var asObject: Any {
		return ["code": code, "message": localizedDescription]
	}
	
	internal static func withObject(_ object: Any?) -> ConnectionError? {
		guard let data = object  as? [Any],
		      let code = data[0] as? Int else {
			return nil
		}
		return ConnectionError(code: code, description: data[safe: 1] as? String)
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

public enum ConnectionErrorType: Int {
	case appNotFound = 10
	case authFailed = 11
	case interfaceNotFound = 12
	case interfaceIncompatible = 13
	case methodNotFound = 14
	case notSerever = 15
	case internalError = 16
	case invalidSignature = 17
}
