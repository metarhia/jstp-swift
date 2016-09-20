//
//  Application.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/4/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public class Application {
   
   public typealias Function = (Any) -> Void
    
   internal var methods: [String:[String:Function]]
    
   init() {
      methods = [String:[String:Function]]()
   }
   
   open func register(_ interface: String, name: String, function: @escaping Function) {
        
      if var functions = methods[interface] {
         functions[name] = function
         return
      }
        
      methods[interface] = [name:function]
   }
    
   open func removeHandler(_ interface: String, name: String) {
        
      if var functions = methods[interface] {
         functions.removeValue(forKey: name)
      }
   }
    
   open func removeHandles(_ interface: String) {
      methods.removeValue(forKey: interface)
   }
    
}

