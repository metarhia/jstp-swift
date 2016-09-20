//
//  Chunks.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import Foundation
import JavaScriptCore

internal class Chunks {
   
   fileprivate var buffer: String
   
   init() {
      buffer = kChunksFirst
   }
   
   func add(_ chunk: String) -> JSValue! {
      
      buffer += chunk
      
      guard chunk.hasSuffix(kPacketDelimiter) else {
         return nil
      }
      
      let chunks = buffer + kChunksLast
          buffer = kChunksFirst
         
      let packets = JSTP.parse(chunks)
      
      guard packets.isUndefined == false,
            packets.isNull      == false else {
            
         return nil
      }
      
      return packets
   }
   
}

