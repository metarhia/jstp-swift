//
//  ViewController.swift
//  JSTPhone
//
//  Created by Artem Chernenkiy on 28.03.16.
//  Copyright © 2016 Test. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController {

    @IBOutlet var testButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func testRunner(sender: AnyObject) {
        
        let metadata =
            "({" +
                "name:'string'," +
                "passport:'string(8)'," +
                "birth:'Date'," +
                "age:'number'," +
            "})"
        
        let data = "['Marcus Aurelius','AE127095','1990-02-15',26]"
        
        NSLog("begin")
        
        for _ in 0...250000 {
            let _ = JSTPObject(data: data, metadata: metadata)
        }
        
        NSLog("end")
        
        NSLog("ggwp")
        
        JSGarbageCollect(context.JSGlobalContextRef)
                
    }
}

