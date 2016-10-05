//
//  Context.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import JavaScriptCore

internal class Context {
   
   internal static let shared: Context = Context()
   
   private let context   : JSContext!
   private let stringify : JSValue!
   private let packet    : JSValue!
   
   internal init() {
      
      let bundle = Bundle(for: Context.self)
      
      let path = bundle.path(forResource: "Common", ofType: "js")!
      let text = try? String(contentsOfFile: path)
      
      context = JSContext()
      
      context.exceptionHandler = { context, exception in
         print("Error in \(context): \(exception)")
      }
      
      context.evaluateScript(text)
      
      stringify = context.objectForKeyedSubscript("stringify")
      packet    = context.objectForKeyedSubscript("Packet"   )
   }
   
   // MARK: Methods
   
   internal func stringify(_ argument: AnyObject) -> String {
      return stringify.call(withArguments: [argument]).toString()
   }
   
   internal func packet(_ arguments: [AnyObject]) -> JSValue {
      return packet.construct(withArguments: arguments)
   }
   
   internal func parse(_ string: String) -> JSValue {
      return context.evaluateScript(string)
   }
   
}

