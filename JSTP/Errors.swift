//
//  Errors.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 7/25/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

internal extension NSError {
   
   internal convenience init(_ code: Int, _ description: String) {
      
      let domain = Bundle.main.bundleIdentifier!
      let info   = [NSLocalizedDescriptionKey:description]
      
      self.init(domain: domain, code: code, userInfo: info)
   }

   internal convenience init?(_ object: Any?) {
      
      guard let data = object  as? [Any],
            let code = data[0] as? Int else {
      
         return nil
      }
   
      var description: String!
      
      if data.count == 2 {
         description = data[1] as? String
      }
      
      description = description ?? Errors.kErrors[code] ?? "Undefined error"
      
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
   
   open static let InterfaceIncompatible = NSError(13, "Incompatible interface")
   open static let ApplicationNotFound   = NSError(10, "Application not found" )
   open static let AuthorizationFailed   = NSError(11, "Authentication failed" )
   open static let InterfaceNotFound     = NSError(12, "Interface not found"   )
   open static let InternalError         = NSError(16, "Internal API error"    )
   open static let MethodNotFound        = NSError(14, "Method not found"      )
   open static let NotSerever            = NSError(15, "Not a server"          )
   
   fileprivate static let kErrors = [
      13: "Incompatible interface",
      10: "Application not found",
      11: "Authentication failed",
      12: "Interface not found",
      16: "Internal API error",
      14: "Method not found",
      15: "Not a server",
   ]
   
}
