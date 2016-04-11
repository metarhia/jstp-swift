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

    private init() { }

    public static func parse(str: String) -> [AnyObject] {
        return JSTPOS(data: str).parsed as [AnyObject]
    }

    public static func intertprete(str: String) -> NSObject! {
        return JSTPOS(data: str).interpreted as! NSObject
    }

    public static func jsrd(data: String, metadata: String) -> NSObject! {
        return JSTPRM(data: data, metadata: metadata).jsrd as! NSObject
    }
}

extension jstp {
    private static func writeData(data: String) {
        context.evaluateScript("var data=\(data);")
    }
}


private struct JSTPOS {

    weak var parsed: NSArray! {
        let arr = context.objectForKeyedSubscript("data").toArray()
                  context.deleteJSProperty("data")
        return arr
    }

    weak var interpreted: AnyObject! {
        let obj = context.objectForKeyedSubscript("data").toObject()
                  context.deleteJSProperty("data")
        return obj
    }

    init(data: String) {
        jstp.writeData(data)
    }
}


private struct JSTPRM {

    weak var jsrd: AnyObject! {
        let obj = metaContext.objectForKeyedSubscript("jsrd").callWithArguments(
                     [context.objectForKeyedSubscript("data"),
                  metaContext.objectForKeyedSubscript("meta" + self.id)]).toObject()
                      context.deleteJSProperty("data")
        return obj
    }
    var id = (NSUUID().UUIDString as NSString).substringToIndex(3)

    init(data: NSData, metadata: NSData) {
        self.init(data: NSString(data:     data, encoding: NSUTF8StringEncoding) as! String,
              metadata: NSString(data: metadata, encoding: NSUTF8StringEncoding) as! String)
    }

    init(data: String, metadata: String) {
        self.writeMetadata(metadata)
        jstp.writeData(data)
    }

    /**
     * TODO: redo metadata initialization.
     */
    mutating func writeMetadata(metadata: String) {
        if let value = metadataCache[metadata.hash] { self.id = value }
        else {
            metaContext.evaluateScript("var meta" + self.id + "=\(metadata);")
            metadataCache.updateValue(self.id, forKey: metadata.hash)
        }
    }
}

extension NSObject {
    public subscript(key: String) -> AnyObject? { return self.valueForKey(key) }
}

extension JSContext {
    private func deleteJSProperty(name: String) {
        JSObjectDeleteProperty(self.JSGlobalContextRef,
                               self.globalObject.JSValueRef,
                               self.objectForKeyedSubscript(name).JSValueRef, nil)
              JSGarbageCollect(self.JSGlobalContextRef)
    }
}