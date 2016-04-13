//
//  JSTPObject.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 29.03.16.
//  Copyright © 2016 Test. All rights reserved.
//

import JavaScriptCore

private let stringApi     = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

private let api = JSContext().evaluateScript(stringApi).context
private let context = JSContext(virtualMachine: api.virtualMachine)

private let JSQueue = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)

private var metadataCache = [Int : String]()


public struct JSTPObject {
    
    public var JSObject: AnyObject!
    private var id = (NSUUID().UUIDString as NSString).substringToIndex(3)
    
    public init() { JSObject = nil }
    
    public init(data: NSData, metadata: NSData) {
        self.init(data: NSString(data: data, encoding: NSUTF8StringEncoding) as! String,
            metadata: NSString(data: metadata, encoding: NSUTF8StringEncoding) as! String)
    }
    
    public init(data: String, metadata: String) {
        let signal = dispatch_semaphore_create(0)
        
        dispatch_async(JSQueue) {
            self.initData(data)
            self.initMetadata(metadata)
            self.JSObject = api["jsrd"].callWithArguments(
                [context["data"], context["meta" + self.id]]).toObject()
            dispatch_semaphore_signal(signal)
        };  dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER)
    }
    
    public func initData(data: String) { context.evaluateScript("var data = \(data)") }
    
    private mutating func initMetadata(metadata: String) {
        if let value = metadataCache[metadata.hash] { self.id = value }
        else {
            context.evaluateScript("var meta" + self.id + " = \(metadata);")
            metadataCache.updateValue(self.id, forKey: metadata.hash)
        }
    }
    
    public subscript(key: String) -> AnyObject? {
        if let value =  JSObject.valueForKey(key) { return value }
        else { return nil }
    }
}

extension JSContext {
    private subscript(key: String) -> JSValue { return self.objectForKeyedSubscript(key) }
}