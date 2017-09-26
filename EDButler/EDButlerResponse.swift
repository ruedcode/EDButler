//
//  EDButlerResponse.swift
//  EDButler
//
//  Created by Eugene Kalyada on 26.09.17.
//  Copyright © 2017 Edcode. All rights reserved.
//

import UIKit

open class EDButlerResponse<T> where T:Codable{

	var response: URLResponse?
	var error: Error?
	fileprivate var data: Data?

	init(data:Data?, response:URLResponse?, error:Error? ) {
		self.data = data
		self.response = response
		self.error = error
	}

	var value: T? {
		get {
			if let data = data {
				let decoder = JSONDecoder()
				return try? decoder.decode(T.self, from: data)
			}
			return nil

		}
	}

}
