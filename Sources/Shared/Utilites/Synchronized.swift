//
//  Synchronized.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 6/12/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

@inline(__always) internal func synchronized<R> (_ lock: AnyObject, block: () throws -> R) rethrows -> R {
	objc_sync_enter(lock)
	defer {
		objc_sync_exit(lock)
	}
	return try block()
}
