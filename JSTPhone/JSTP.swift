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

public let JSQueue        = dispatch_queue_create("JS", DISPATCH_QUEUE_CONCURRENT)
private let context       = JSContext().evaluateScript(api).context
private var metadataCache = [Int :  String]()
/**
 * a — api, d — data, m — metadata
 */
public struct jstp {

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

private class JSTPOS {

    init(data: String) {
        jstp.writeData(data)
    }
    deinit {
        JSGarbageCollect(context.JSGlobalContextRef)
    }

    weak var parsed: NSArray! {
        let arr = context["a"]["d"].toArray()
        return arr
    }

    weak var interpreted: AnyObject! {
        let obj = context["a"]["d"].toObject()
        return obj
    }
}

private class JSTPRM {

    init(data: String, metadata: String) {
        self.writeMetadata(metadata)
        jstp.writeData(data)
    }
    deinit {
        JSGarbageCollect(context.JSGlobalContextRef)
    }

    var id = (NSUUID().UUIDString as NSString).substringToIndex(8)

    weak var jsrd: AnyObject! {
        let obj = context["jsrd"].callWithArguments(
                 [context["a"]["d"],
                  context["a"]["m" + self.id]]).toObject()
        return obj
    }

    func writeMetadata(metadata: String) {
        if let value = metadataCache[metadata.hash] { self.id = value }
        else {
            context.evaluateScript("a.m" + self.id  + "=\(metadata);")
            metadataCache.updateValue(self.id, forKey: metadata.hash)
        }
    }
}

public class JSTP {
    private static var id: String!
    private static var jsrs: AnyObject!

    deinit { print("dawd"); JSGarbageCollect(context.JSGlobalContextRef) }

    public static func parse(str: String) -> [AnyObject] {
        return JSTP.onPostExecute { () -> AnyObject in
            return intertprete(str)
        } as! [AnyObject]
    }

    public static func intertprete(str: String) -> NSObject! {
        return JSTP.onPostExecute { () -> AnyObject in
            return context.evaluateScript(str).toObject()
        } as! NSObject
    }

    public static func jsrd(data data: String, metadata: String) -> NSObject! {
        return JSTP.onPostExecute { () -> AnyObject in
            let JSM = context.evaluateScript(metadata)
            let JSD = context.evaluateScript(data)
            return context.objectForKeyedSubscript("jsrd").callWithArguments([JSD, JSM])
        }.toObject() as! NSObject
    }

    private func writeMetadata(metadata: String) {

        if let value = metadataCache[metadata.hash] { JSTP.id = value }
        else {
            JSTP.id = (NSUUID().UUIDString as NSString).substringToIndex(8)
            context.evaluateScript("a.m" + JSTP.id  + "=\(metadata);")
            metadataCache.updateValue(JSTP.id, forKey: metadata.hash)
        }
    }

    private static func onPostExecute(execute: () -> AnyObject) -> AnyObject {
        var result: AnyObject = NSObject()
        let signal = dispatch_semaphore_create(0)
        dispatch_async(JSQueue) {
            result = execute()
            dispatch_semaphore_signal(signal)
        }; dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER)
        return result
    }
}

extension JSContext {
    private subscript(key: String) -> JSValue! { return self.objectForKeyedSubscript(key) }
}
extension JSValue {
    private subscript(key: String) -> JSValue! { return self.valueForProperty(key) }
}
extension NSObject {
    public subscript(key: String) -> AnyObject? { return self.valueForKey(key) }
}

//            if let value = metadataCache[metadata.hash] { JSTP.id = value }
//            else {
//                JSTP.id = (NSUUID().UUIDString as NSString).substringToIndex(8)
//                context.evaluateScript("a.m" + JSTP.id  + "=\(metadata);")
//                metadataCache.updateValue(JSTP.id, forKey: metadata.hash)
//            }
//            return context["jsrd"].callWithArguments(
//                [context.evaluateScript(data), context["a"]["m" + JSTP.id]]).toObject() as! NSObject

