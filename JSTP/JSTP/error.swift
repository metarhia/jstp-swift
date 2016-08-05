//
//  Errors.swift
//  jstp.demo.dev
//
//  Created by Andrew Visotskyy on 7/25/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation
import JavaScriptCore

public class Error {

   public dynamic var code: Int
   public dynamic var message: String
   
   public init(code: Int, message: String) {
      self.code = code
      self.message = message
   }
   
   public init(code: Int) {
      self.code = code
      self.message = ""
   }
   
   public var toArray: [AnyObject] {
      return [code, message]
   }
   
}

extension Error {
   
   public static let InterfaceIncompatible = Error(code: 13, message: "Incompatible interface")
   public static let ApplicationNotFound   = Error(code: 10, message: "Application not found" )
   public static let AuthorizationFailed   = Error(code: 11, message: "Authentication failed" )
   public static let InterfaceNotFound     = Error(code: 12, message: "Interface not found"   )
   public static let MethodNotFound        = Error(code: 14, message: "Method not found"      )
   
}