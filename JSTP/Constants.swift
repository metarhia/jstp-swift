//
//  Constants.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

internal let kPacketDelimiter       = "\u{0}"
internal let kPacketDelimiterLength = kPacketDelimiter.characters.count
internal let kChunksFirst           = "["
internal let kChunksLast            = "]"

public typealias Callback  = (AnyObject?, Error?) -> Void
public typealias Callbacks = [Int:Callback]

internal typealias Packet = [AnyHashable:AnyObject]
