//
//  Event.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation

open class Event {
   
   open let arguments: Any
   open let interface: String
   open let name: String
   
   init(_ interface: String, _ name: String, _ arguments: Any) {
      self.arguments = arguments
      self.interface = interface
      self.name = name
   }
   
}

