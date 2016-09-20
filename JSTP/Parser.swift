//
//  Parser.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation
import JavaScriptCore

open class JSTP { }

// -------------------------------------------------------------------
// Java Script Context used to evaluate scripts and to parse input and
// output data
//
// ??? TODO: refactor this in something more reliable

fileprivate func createJavaScriptContext() -> JSContext {
   
   let path = Bundle(for: Connection.self).path(forResource: "Common", ofType: "js")
   let text = try? String(contentsOfFile: path!)
   let ctx  = JSContext()
   
   ctx?.exceptionHandler = { context, exception in
      print("JS Error in \(context): \(exception)")
   }
   
   _ = ctx?.evaluateScript(text)
   
   return ctx!
}

internal let jsContext = createJavaScriptContext()

// -------------------------------------------------------------------

internal extension JSTP {
   class func parse(_ data: String) -> JSValue {
      return jsContext.evaluateScript(data)
   }
}

