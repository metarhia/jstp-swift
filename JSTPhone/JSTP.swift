//
//  JSTPObject.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 29.03.16.
//  Copyright © 2016 Test. All rights reserved.
//

import JavaScriptCore

private let api = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

private let metaContext   = JSContext().evaluateScript(api).context
private let context       = JSContext(virtualMachine: metaContext.virtualMachine)
private let JSQueue       = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)
private var metadataCache = [Int : String]()

public class jstp {

    public static func parse(str: String) -> [AnyObject] {
        return JSTPObject(data: str).parse as [AnyObject]
    }

    public static func intertprete(str: String) -> AnyObject {

        return NSObject() //zaglushka
    }

    public static func jsrd(data: String, metadata: String) -> NSObject {
        return JSTPObject(data: data, metadata: metadata).jsrd as! NSObject
    }
}

/**
 * TODO: add proper caching and optimize.
 */
public struct JSTPObject {

    public weak var jsrd: AnyObject! {
        let obj = metaContext["jsrd"].callWithArguments(
                     [context["data"], metaContext["meta" + self.id]]).toObject()
                      context.deleteJSProperty("data")
        return obj
    }
    public weak var parse: NSArray! {
        let arr = context["data"].toArray()
                  context.deleteJSProperty("data")
        return arr
    }
    private var id = (NSUUID().UUIDString as NSString).substringToIndex(3)

    public init(data: NSData, metadata: NSData) {
        self.init(data: NSString(data:     data, encoding: NSUTF8StringEncoding) as! String,
              metadata: NSString(data: metadata, encoding: NSUTF8StringEncoding) as! String)
    }

    public init(data: String) {
        self.initData(data)
    }

    public init(data: String, metadata: String) {
            self.initData(data)
            self.initMetadata(metadata)
    }

    /**
     * TODO: redo data initialization to avoid multiple writing to context.
     */
    public func initData(data: String) { context.evaluateScript("var data = \(data)") }
//    public func initData(data: String) { context.evaluateScript("\(data)") }

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
}

extension NSObject {
    public subscript(key: String) -> AnyObject? { return self.valueForKey(key) }
}

extension JSContext {
    private subscript(key: String) -> JSValue { return self.objectForKeyedSubscript(key) }

    private func deleteJSProperty(name: String) {
        JSObjectDeleteProperty(self.JSGlobalContextRef,
                               JSContextGetGlobalObject(self.JSGlobalContextRef),
                               self[name].JSValueRef, nil)
        JSGarbageCollect(self.JSGlobalContextRef)
    }
}