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

//private let metaContext   = JSContext().evaluateScript(api).context
//private let context       = JSContext(virtualMachine: metaContext.virtualMachine)
private let context = JSContext().evaluateScript(api).context
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

    public static func jsrd(data data: String, metadata: String) -> NSObject! {
        return JSTPRM(data: data, metadata: metadata).jsrd as! NSObject
    }
}

extension jstp {

    private static func writeData(data: String) {
        //context.evaluateScript("var data=\(data);")
        metaContext.evaluateScript("api.data = \(data)")
    }
}

private struct JSTPOS {

    weak var parsed: NSArray! {
//        let arr = context.globalObject.valueForProperty("data").toArray()
//                  context.globalObject.deleteProperty("var data")
//        JSGarbageCollect(context.JSGlobalContextRef)
//        return arr
        let arr = metaContext.objectForKeyedSubscript("api").valueForProperty("data").toArray()
        metaContext.objectForKeyedSubscript("api").deleteProperty("data")
        if !metaContext.objectForKeyedSubscript("api").hasProperty("data") {
            print(#function)
        }
        JSGarbageCollect(context.JSGlobalContextRef)
        return arr
    }

    weak var interpreted: AnyObject! {
        let obj = context.globalObject.valueForProperty("data").toObject()
                  //context.globalObject.deleteProperty("var data")
        if !context.globalObject.deleteProperty("var data") {
            print(#function)
        }
        JSGarbageCollect(context.JSGlobalContextRef)
        return obj
    }

    init(data: String) {
        jstp.writeData(data)
    }
}

private struct JSTPRM {

    weak var jsrd: AnyObject! {
        let obj = metaContext.objectForKeyedSubscript("jsrd").callWithArguments(
                     [context.globalObject.valueForProperty("data"),
                  metaContext.objectForKeyedSubscript("meta" + self.id)]).toObject()
                      context.globalObject.deleteProperty("var data")
        JSGarbageCollect(context.JSGlobalContextRef)
        return obj
    }
    var id = (NSUUID().UUIDString as NSString).substringToIndex(3)

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









