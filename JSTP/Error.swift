//
//  Errors.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/25/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public typealias Error = NSError

internal extension Error {
   
   internal convenience init(_ code: Int, _ description: String) {
      
      let domain = Bundle.main.bundleIdentifier!
      let info   = [NSLocalizedDescriptionKey:description]
      
      self.init(domain: domain, code: code, userInfo: info)
   }

   internal convenience init?(_ object: Any) {
      
      
      guard let data = object as? [Any],
            let code = data[0] as? Int,
            let description = data[1] as? String else {
            
         return nil
      }
      
      self.init(code, description)
      
   }
   
   internal func raw() -> AnyObject {
         
      let error =  [
         "message":self.localizedDescription,
         "code"   :self.code
         
      ] as [String : Any]
         
      return error as AnyObject
   }
   
}

open class Errors {
   
   open static let InterfaceIncompatible = Error(13, "Incompatible interface")
   open static let ApplicationNotFound   = Error(10, "Application not found" )
   open static let AuthorizationFailed   = Error(11, "Authentication failed" )
   open static let InterfaceNotFound     = Error(12, "Interface not found"   )
   open static let MethodNotFound        = Error(14, "Method not found"      )
}

