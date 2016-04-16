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

private let JSQueue       = dispatch_queue_create("JS", DISPATCH_QUEUE_CONCURRENT)
private let context       = JSContext().evaluateScript(api).context
private var metadataCache = [Int :  String]()

/**
 * a — api, d — data, m — metadata
 */
public class JSTP {

    private init() { }
    deinit { JSGarbageCollect(context.JSGlobalContextRef) }

    public static func parse(str: String) -> [AnyObject] {
        return JSTP()._parse(str)
    }
    public static func interprete(str: String) -> NSObject! {
        return JSTP()._interprete(str)
    }
    public static func jsrd(data data: String, metadata: String) -> NSObject! {
        return JSTP()._jsrd(data: data, metadata: metadata)
    }

    private func _parse(str: String) -> [AnyObject] {
        return self.onPostExecute { () -> AnyObject in
            return context.evaluateScript(str).toArray()
            } as! [AnyObject]
    }
    private func _interprete(str: String) -> NSObject! {
        return onPostExecute { () -> AnyObject in
            return context.evaluateScript(str).toObject()
            } as! NSObject
    }
    private func _jsrd(data data: String, metadata: String) -> NSObject! {
        // metadata initializing
        let id: String
        if let value = metadataCache[metadata.hash] { id = value }
        else {
            id = (NSUUID().UUIDString as NSString).substringToIndex(8)
            context.evaluateScript("a.m\(id)=\(metadata);")
            metadataCache.updateValue(id, forKey: metadata.hash)
        }
        // data parsing
        return onPostExecute { () -> AnyObject! in
            return context["jsrd"].callWithArguments([
                   context["a"].objectForKeyedSubscript("m\(id)"),
                   context.evaluateScript(data)]).toObject()
            } as! NSObject
    }

    private func onPostExecute(execute: () -> AnyObject!) -> AnyObject {
        var result: AnyObject! = nil
        let signal = dispatch_semaphore_create(0)
        dispatch_async(JSQueue) {
            result = execute()
            dispatch_semaphore_signal(signal)
        };  dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER)
        return result
    }

}

extension JSContext {
    private subscript(key: String) -> JSValue! { return self.objectForKeyedSubscript(key) }
}
extension NSObject {
    public subscript(key: String) -> AnyObject? { return self.valueForKey(key) }
}