//
//  JSTPObject.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 29.03.16.
//  Updated by Andrew Visotskyi on 04.04.16
//
//  Copyright © 2016 Test. All rights reserved.
//

import UIKit
import JavaScriptCore

//----------------------------------------------------------------------------

let path   = NSBundle.mainBundle().pathForResource("api", ofType: "js")!
let script = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding)

private let context = JSContext().evaluateScript(script).context
private let JSQueue = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)

//----------------------------------------------------------------------------

/**
 * TODO: add caching.
 */
public class JSTPObject {
    
    public var object: AnyObject! = nil
    
    public init(data: String, metadata meta: String) {
        
        let semaphore = dispatch_semaphore_create(0)
        
        dispatch_async(JSQueue) {
            
            let jsMeta = context.evaluateScript(meta)
            let jsData = context.evaluateScript(data)
            
            self.object = context["jsrd"].callWithArguments([jsData, jsMeta]).toObject()
            
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
}

extension JSContext {
    private subscript(key: String) -> JSValue {
        return self.objectForKeyedSubscript(key)
    }
}