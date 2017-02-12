//
//  Collection+Extensions.swift
//  JSTP
//
//  Created by Andrew Visotskyy on 2/12/17.
//  Copyright © 2017 Andrew Visotskyy. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
	
	/// Returns the element at the specified index iff it is within bounds, otherwise nil.
	internal subscript (safe index: Index?) -> Generator.Element? {
		guard let index = index else {
			return nil
		}
		return indices.contains(index) ? self[index] : nil
	}
	
}
