//
//  Errors.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/25/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

internal extension NSError {
   
   private convenience init(_ code: Int, _ description: String) {
      
      let domain = NSBundle.mainBundle().bundleIdentifier!
      let info   = [NSLocalizedDescriptionKey:description]
      
      self.init(domain: domain, code: code, userInfo: info)
   }
   
   internal func raw() -> AnyObject {
         
      let error =  [
         "message":self.localizedDescription,
         "code"   :self.code
      ]
         
      return error
   }
   
}

public class Errors {
   
   public static let InterfaceIncompatible = NSError(13, "Incompatible interface")
   public static let ApplicationNotFound   = NSError(10, "Application not found" )
   public static let AuthorizationFailed   = NSError(11, "Authentication failed" )
   public static let InterfaceNotFound     = NSError(12, "Interface not found"   )
   public static let MethodNotFound        = NSError(14, "Method not found"      )
}

