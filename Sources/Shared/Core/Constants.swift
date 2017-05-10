//
//  Constants.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/18/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

internal let kPacketDelimiter = "\u{0}"
internal let kChunksFirst = "["
internal let kChunksLast = "]"

public typealias Value = Any

public typealias Callback  = ([Value]?, Error?) -> Void
public typealias Callbacks = [Int:Callback]
