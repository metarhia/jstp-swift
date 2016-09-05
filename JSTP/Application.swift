//
//  Application.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/4/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

public class Application {
    
    public typealias Function = (object: AnyObject) -> Void
    
    internal var methods: [String:[String:Function]]
    
    init() {
        methods = [String:[String:Function]]()
    }
    
    public func register(interface: String, name: String, function: Function) {
        
        if var functions = methods[interface] {
            functions[name] = function
            return
        }
        
        methods[interface] = [name:function]
    }
    
    public func removeHandler(interface: String, name: String) {
        
        if var functions = methods[interface] {
            functions.removeValueForKey(name)
        }
    }
    
    public func removeHandles(interface: String) {
        methods.removeValueForKey(interface)
    }
    
}

