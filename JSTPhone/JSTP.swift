//
//  JSTPhoneTests.swift
//  JSTPhoneTests
//
//  Created by Artem Chernenkiy on 28.03.16.
//  Updated by Nikita Kirichek  on 15.04.16

//  Copyright © 2016 Test. All rights reserved.
//



import JavaScriptCore

private let api = try? String(
    contentsOfFile: NSBundle.mainBundle().pathForResource("api", ofType: "js")!,
    encoding: NSUTF8StringEncoding)

private var metadataStringCache = [String : Int]()
private var metadataObjectCache = [Int : AnyObject]()
private let context = JSContext().evaluateScript(api).context

public class JSTP{
    
    private var id: Int!
    
    public static func parse(data: String) -> [AnyObject]! {
        let result =  intertprete(data) as? [AnyObject]
        JSGarbageCollect(context.JSGlobalContextRef)
        return result
    }
    
    public static func intertprete(data: String) -> NSObject? {
        let result = context.evaluateScript(data).toObject() as? NSObject
        JSGarbageCollect(context.JSGlobalContextRef)
        return result
    }
    
    public func jsrd(data data: String, metadata: String) -> NSObject! {
        if cashing(metadata) {
            let result = context["jsrd"].callWithArguments(
                [context.evaluateScript(data)!, metadataObjectCache[self.id]!]).toObject() as? NSObject
            JSGarbageCollect(context.JSGlobalContextRef)
            return result
        }
        return nil
    }
    
    private func cashing(metadata: String) -> Bool{
        if let value = metadataStringCache[metadata] {
            self.id = value
            return true
            
        } else if let obj =  context.evaluateScript("api.m = \(metadata);").toObject() {
            self.id =  metadataStringCache.values.count
            metadataObjectCache.updateValue(obj, forKey: self.id)
            metadataStringCache.updateValue(self.id, forKey: metadata)
            return true
        }
        
        return false
    }
    
}


extension JSContext {
    private subscript(key: String) -> JSValue! { return self.objectForKeyedSubscript(key) }
}

