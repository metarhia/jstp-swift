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

        let dataURL     = NSBundle.mainBundle().URLForResource("data", withExtension: "js")!
        let metadataURL = NSBundle.mainBundle().URLForResource("metadata", withExtension: "js")!
        let dData       = NSData(contentsOfURL: dataURL)!
        let dMetadata   = NSData(contentsOfURL: metadataURL)!
        let data        = NSString(data: dData, encoding: NSUTF8StringEncoding) as! String
        let metadata    = NSString(data: dMetadata, encoding: NSUTF8StringEncoding) as! String

//        let begin = NSDate()
//        for _ in 1...100000 {
//            let _ = jstp.jsrd(data: data, metadata: metadata)
//        }
//        NSLog("Parse time: \((-begin.timeIntervalSinceNow).description)")
//        print(jstp.jsrd(data: data, metadata: metadata))

        
        let _begin = NSDate()
        for _ in 1...100000 {
            let _ = jstp.parse(data)
        }
        NSLog("Parse time: \((-_begin.timeIntervalSinceNow).description)")
        print(jstp.parse(data))

//        let __begin = NSDate()
//        for _ in 1...10000 {
//            let _ = jstp.intertprete(data)
//        }
//        NSLog("Parse time: \((-__begin.timeIntervalSinceNow).description)")
//        print(jstp.intertprete(data))
    }
}