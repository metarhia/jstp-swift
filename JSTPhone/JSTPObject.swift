//
//  JSTPObject.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 29.03.16.
//  Copyright © 2016 Test. All rights reserved.
//

import UIKit
import JavaScriptCore

private let api     = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

private let context = JSContext().evaluateScript(api).context
private let JSQueue = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)

private var metadataCache = [Int : String]()

/*
 * TODO: add multiple metadata handling and caching.
 */
public struct JSTPObject {

    public var JSObject: AnyObject!
    private var data: String?
    private var id = (NSUUID().UUIDString as NSString).substringToIndex(4)

    public init() {
        JSObject = nil
        data = nil
    }

    public init(data: NSData, metadata: NSData) {
        let data = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        let metadata = NSString(data: metadata, encoding: NSUTF8StringEncoding) as! String

        self.init(data: data, metadata: metadata)
    }

    public init(data: String, metadata: String) {

        onPostExecute { () -> Void in
            self.initData(data)
            self.initMetadata(metadata)

            let object = context!["jsrd"].callWithArguments(
                        [context!["data"], context!["meta" + self.id]])
            if let parsed = object { self.JSObject = parsed.toObject() }
        }
    }

    /*
     * TODO: redo data initialization to avoid multiple writing to context.
     */
    public func initData(data: String) {
        context.evaluateScript("var data = \(data)")
    }

    /*
     * TODO: redo metadata initialization.
     */
    private mutating func initMetadata(metadata: String) {

        if let value = metadataCache[metadata.hash] { self.id = value }
        else {
            context!.evaluateScript("var meta" + self.id + " = \(metadata);")
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
    private subscript(key: String) -> JSValue {
        return self.objectForKeyedSubscript(key)
    }
}