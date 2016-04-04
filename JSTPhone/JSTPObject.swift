//
//  JSTPObject.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 29.03.16.
//  Copyright © 2016 Test. All rights reserved.
//

import UIKit
import JavaScriptCore

private let context = JSContext()
private let undefined = JSValueMakeUndefined(context.JSGlobalContextRef)
private let JSQueue: dispatch_queue_t = dispatch_queue_create("JS", DISPATCH_QUEUE_SERIAL)
private let api = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

/**
 * TODO: add multiple metadata handling and caching.
 */
public struct JSTPObject {

    public var JSObject: AnyObject!
    private var data: String?
    private let id = (NSUUID().UUIDString as NSString).substringToIndex(4)

    public init() {
        JSObject = nil
        data = nil
    }

    public init(data: NSData, metadata: NSData) {
        let data = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        let metadata = NSString(data: metadata, encoding: NSUTF8StringEncoding) as! String

        self.init(data: data, metadata: metadata)
    }

    public init(dataName: String, metadataName: String) {
        let dataURL = NSBundle.mainBundle().URLForResource(dataName, withExtension: "js")!
        let metadataURL = NSBundle.mainBundle().URLForResource(metadataName, withExtension: "js")!

        self.init(dataURL: dataURL, metadataURL: metadataURL)
    }

    public init(dataURL: NSURL, metadataURL: NSURL) {
        let dData = NSData(contentsOfURL: dataURL)!
        let dMetadata = NSData(contentsOfURL: metadataURL)!

        self.init(data: dData, metadata: dMetadata)
    }

    public init(data: String, metadata: String) {

        onPostExecute { () -> Void in
            self.initData(data)
            self.initMetadata(metadata)

            let JSData = JSManagedValue(value: context!["data"])
            let JSMetadata = JSManagedValue(value: context!["metadata\(self.id)"])
            /**
             * TODO: call "api.jstp.jsrd" via subscript.
             */
            let object = JSManagedValue(value: context!.evaluateScript("api.jstp.jsrd").callWithArguments(
                [JSData.value, JSMetadata.value]))

            if let parsed = object.value {
                self.JSObject = parsed.toObject()
            }
        }
    }

    /**
     * TODO: redo data initialization to avoid multiple writing to context.
     */
    public func initData(data: String) {
        context.evaluateScript("var data = \(data)")
    }

    /**
     * TODO: redo metadata initialization.
     */
    private func initMetadata(metadata: String) {

        if context!.objectForKeyedSubscript("metadata\(self.id)").JSValueRef == undefined {
                context!.evaluateScript(" \(api!);"
                    + "var metadata\(self.id) = \(metadata);")
        }
    }

    private func onPostExecute(complete: () -> Void) {
        let semaphore = dispatch_semaphore_create(0)
        dispatch_async(JSQueue) {
            complete()
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    public subscript(key: String) -> AnyObject? {
        if let value = self.JSObject.valueForKey(key) {
            return value
        } else { return nil }
    }
}

extension JSContext {
    private subscript(key: String) -> JSValue {
        return self.objectForKeyedSubscript(key)
    }
}