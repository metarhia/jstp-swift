//
//  Event.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

open class Event {
   
   open let arguments: AnyObject
   open let interface: String
   open let name: String
   
   init(_ interface: String, _ name: String, _ arguments: AnyObject) {
      self.arguments = arguments
      self.interface = interface
      self.name = name
   }
   
}

