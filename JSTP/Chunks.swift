//
//  Chunks.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

import JavaScriptCore

internal class Chunks {
   
   private var buffer: Data
   
   init() {
      buffer = Data()
   }
   
   func add(_ chunk: Data) -> JSValue? {
      
      buffer.append(chunk)
      
      guard let source = String(data: buffer, encoding: .utf8), source.hasSuffix(kPacketDelimiter) else {
         return nil
      }
      
      buffer = Data()

      let chunks = (kChunksFirst + source + kChunksLast).replacingOccurrences(of: kPacketDelimiter, with: ",")
      let packets = Context.shared.parse(chunks)
      
      guard packets.isUndefined == false, packets.isNull == false else {
         return nil
      }
      
      return packets
   }
   
}
