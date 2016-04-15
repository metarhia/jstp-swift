//
//  JSTPhoneTests.swift
//  JSTPhoneTests
//
//  Created by Artem Chernenkiy on 28.03.16.
//  Updated by Nikita Kirichek  on 15.04.16

//  Copyright © 2016 Test. All rights reserved.
//

import XCTest
@testable import JSTPhone

class JSTPhoneTests: XCTestCase {
    
    let data        = NSString(data:  NSData(contentsOfURL:  NSBundle.mainBundle().URLForResource("data", withExtension: "js")!)! , encoding: NSUTF8StringEncoding) as! String
    let metadata    = NSString(data:  NSData(contentsOfURL:  NSBundle.mainBundle().URLForResource("metadata", withExtension: "js")!)!, encoding: NSUTF8StringEncoding) as! String
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testValidPrser() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let interpretedObj = JSTP.intertprete(self.data)!
        XCTAssertNotNil(interpretedObj, "Cannot read data.")
        
        let parsedObj = JSTP.parse(self.data)
        XCTAssertNotNil(parsedObj, "Cannot read data.")
        
        let jsrdObj = JSTP().jsrd(data: self.data, metadata: self.metadata)
        XCTAssertNotNil(jsrdObj, "Cannot read metadata.")
    }
    
    func testPerformanceInterprete() {
        self.measureBlock {
            for _ in 1...100000{
                let _ = JSTP.intertprete(self.data)
            }
            print(JSTP.intertprete(self.data)!)
        }
    }
    
    func testPerformanceParse() {
        self.measureBlock {
            
            for _ in 1...100000 {
                let _ = JSTP.parse(self.data)
            }
            print(JSTP.parse(self.data)!)
        }
    }
    
    
    func testPerformanceJSRD() {
        self.measureBlock {
            for _ in 1...100000 {
                let _ = JSTP().jsrd(data: self.data, metadata: self.metadata)
            }
            print(JSTP().jsrd(data: self.data, metadata: self.metadata)!)
            
        }
    }
    
    
}













