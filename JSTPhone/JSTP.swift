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

public let JSQueue       = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)
private let context       = JSContext().evaluateScript(api).context
private var metadataCache = [Int :  String]()
/**
 * a — api, d — data, m — metadata
 */
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
       context.evaluateScript("a.d=\(data);")
    }
}

private struct JSTPOS {

    weak var parsed: NSArray! {
        let arr = context.objectForKeyedSubscript("a").valueForProperty("d").toArray()
        JSGarbageCollect(context.JSGlobalContextRef)
        return arr
    }

    weak var interpreted: AnyObject! {
        let obj = context.objectForKeyedSubscript("a").valueForProperty("d").toObject()
        JSGarbageCollect(context.JSGlobalContextRef)
        return obj
    }

    init(data: String) {
        jstp.writeData(data)
    }
}

private struct JSTPRM {

    weak var jsrd: AnyObject! {
        let obj = context.objectForKeyedSubscript("jsrd").callWithArguments(
                 [context.objectForKeyedSubscript("a").valueForProperty("d"),
                  context.objectForKeyedSubscript("a").objectForKeyedSubscript("m" + self.id)]).toObject()
        JSGarbageCollect(context.JSGlobalContextRef)
        return obj
    }
    var id = (NSUUID().UUIDString as NSString).substringToIndex(8)

    init(data: String, metadata: String) {
        self.writeMetadata(metadata)
        jstp.writeData(data)
    }

    mutating func writeMetadata(metadata: String) {
        if let value = metadataCache[metadata.hash] { self.id = value }
        else {
            context.evaluateScript("a.m" + self.id  + "=\(metadata);")
            metadataCache.updateValue(self.id, forKey: metadata.hash)
        }
    }
}

extension NSObject {
    public subscript(key: String) -> AnyObject? { return self.valueForKey(key) }
}
