//
//  JSTP.swift
//  JSTPhone
//
//  Created by Nikita Kirichek on 13.04.16.
//  Copyright © 2016 Test. All rights reserved.
//

import JavaScriptCore


import JavaScriptCore

private let api = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

private var metaCache = NSMutableArray()
private let context = JSContext().evaluateScript(api).context

public class JSTP{
    
    private var id: Int!
    
    public static func parse(data: String) -> [AnyObject]! {
        if let value =  intertprete(data){
            return value as! [AnyObject]
        }
        return nil
    }
    
    public static func intertprete(data: String) -> NSObject! {
        if let value = context.evaluateScript("api.data = \(data);").toObject(){
            JSGarbageCollect(context.JSGlobalContextRef)
            return value as! NSObject
        }
        JSGarbageCollect(context.JSGlobalContextRef)
        return nil
    }
    
    public func jsrd(data data: String, metadata: String) -> NSObject! {
        self.cashing(metadata)
        return context.objectForKeyedSubscript("jsrd").callWithArguments(
            [JSTP.intertprete(data), metaCache[id]]).toObject() as! NSObject
        
    }
    
    private func cashing(metadata: String) {
        let obj = JSTP.intertprete(metadata)
        if metaCache.containsObject(obj){
            self.id = metaCache.indexOfObject(obj)
        } else {
            metaCache.addObject(obj)
            self.id = metaCache.count - 1
        }
    }
    
}
