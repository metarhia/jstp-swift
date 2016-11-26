//
//  Chunks.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

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
      
      var chunks = buffer + kChunksLast
          buffer = kChunksFirst
      
      chunks = chunks.replacingOccurrences(of: kPacketDelimiter, with: ",")
      
      let packets = Context.shared.parse(chunks)
      
      guard packets.isUndefined == false,
            packets.isNull      == false else {
            
         return nil
      }
      
      return packets
   }
   
}
