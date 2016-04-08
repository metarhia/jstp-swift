//
//  JSTPObject.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 29.03.16.
//  Copyright © 2016 Test. All rights reserved.
//

import JavaScriptCore

private let api     = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

private let metaContext   = JSContext().evaluateScript(api).context
private let context       = JSContext(virtualMachine: metaContext.virtualMachine)
private let JSQueue       = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)
private var metadataCache = [Int : String]()

/**
 * TODO: add proper caching and optimize.
 */
public struct JSTPObject {

    private var _JSObject: AnyObject!
    public var JSObject: AnyObject! {
        get {
            return metaContext["jsrd"].callWithArguments(
                [context["data"], metaContext["meta" + self.id]]).toObject()
        }
        set { _JSObject = newValue }
    }
    private var id = (NSUUID().UUIDString as NSString).substringToIndex(3)

    public init() { JSObject = nil }

    public init(data: NSData, metadata: NSData) {
        self.init(data: NSString(data: data, encoding: NSUTF8StringEncoding) as! String,
              metadata: NSString(data: metadata, encoding: NSUTF8StringEncoding) as! String)
    }

    public init(data: String, metadata: String) {
        onPostExecute { () -> Void in
            self.initData(data)
            self.initMetadata(metadata)
        }
    }

    /**
     * TODO: redo data initialization to avoid multiple writing to context.
     */
    public func initData(data: String) { context.evaluateScript("var data = \(data)") }

    /**
     * TODO: redo metadata initialization.
     */
    private mutating func initMetadata(metadata: String) {
        if let value = metadataCache[metadata.hash] { self.id = value }
        else {
            metaContext.evaluateScript("var meta" + self.id + " = \(metadata);")
            metadataCache.updateValue(self.id, forKey: metadata.hash)
        }
    }

    private func onPostExecute(execution: () -> Void) {
        let signal = dispatch_semaphore_create(0)
        dispatch_async(JSQueue) {
            execution()
            dispatch_semaphore_signal(signal)
        };  dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER)
    }

    public subscript(key: String) -> AnyObject? {
        if let value = self.JSObject.valueForKey(key) { return value }
        else { return nil }
    }
}

extension JSContext {
    private subscript(key: String) -> JSValue { return self.objectForKeyedSubscript(key) }
}