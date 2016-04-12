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

private let context = JSContext().evaluateScript(api).context
private let JSQueue       = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)
private var metadataCache = [Int : String]()

public class jstp {

    private init() { }

    public static func parse(str: String) -> [AnyObject] {
//        var obj = [AnyObject]()
//               let signal = dispatch_semaphore_create(0)
//               dispatch_async(JSQueue) {
//                    obj = JSTPOS(data: str).parsed as [AnyObject]
//                    dispatch_semaphore_signal(signal)
//                }; dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER)
//        return obj
        return JSTPOS(data: str).parsed as [AnyObject]
    }

    public static func intertprete(str: String) -> NSObject! {
        return JSTPOS(data: str).interpreted as! NSObject
    }

    public static func jsrd(data data: String, metadata: String) -> NSObject! {
//        var obj = NSObject()
//               let signal = dispatch_semaphore_create(0)
//               dispatch_async(JSQueue) {
//                    obj = JSTPRM(data: data, metadata: metadata).jsrd as! NSObject
//                    dispatch_semaphore_signal(signal)
//                }; dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER)
//        return obj
        return JSTPRM(data: data, metadata: metadata).jsrd as! NSObject
    }
}

extension jstp {

    private static func writeData(data: String) {
       context.evaluateScript("api.data=\(data);")
    }
}

private struct JSTPOS {

    weak var parsed: NSArray! {
        let arr = context.objectForKeyedSubscript("api").valueForProperty("data").toArray()
        JSGarbageCollect(context.JSGlobalContextRef)
        return arr
    }

    weak var interpreted: AnyObject! {
        let obj = context.objectForKeyedSubscript("api").valueForProperty("data").toObject()
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
                 [context.objectForKeyedSubscript("api").valueForProperty("data"),
                  context.objectForKeyedSubscript("meta" + self.id)]).toObject()
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
            context.evaluateScript("var meta" + self.id + "=\(metadata);")
            metadataCache.updateValue(self.id, forKey: metadata.hash)
        }
    }
}

extension NSObject {
    public subscript(key: String) -> AnyObject? { return self.valueForKey(key) }
}









