//
//  Application.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 9/4/16.
//  Copyright © 2016-2017 Andrew Visotskyy. All rights reserved.
//

public typealias Function    = (Values) -> Value
public typealias Interface   = [String:Function]
public typealias Application = [String:Interface]
