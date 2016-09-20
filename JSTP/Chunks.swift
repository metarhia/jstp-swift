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
      
      guard chunk.hasSuffix(kPacketDelimiter) else {
         return nil
      }
      
      let index  = chunk.characters.index(chunk.endIndex, offsetBy: -kPacketDelimiterLength + 1)
      let nChunk = chunk.substring(to: index)
      var chunks = buffer
         
      chunks.append(nChunk)
      chunks.append(kChunksLast)
         
      buffer = kChunksFirst
         
      let packets: JSValue = JSTP.parse(chunks)
         
      return (packets.isNull || packets.isUndefined) ? nil : packets
   }
   
}

