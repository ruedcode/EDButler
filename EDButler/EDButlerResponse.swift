//
//  EDButlerResponse.swift
//  EDButler
//
//  Created by Eugene Kalyada on 26.09.17.
//  Copyright © 2017 Edcode. All rights reserved.
//

import UIKit

open class EDButlerResponse<T> where T:Codable{

	open var response: URLResponse?
	open var error: Error?
	fileprivate var data: Data?

	init(data:Data?, response:URLResponse?, error:Error? ) {
		self.data = data
		self.response = response
		self.error = error
	}

	open var value: T? {
		get {
			if let data = data {
				do {
					print("data \(data)")
					let dataString = String(bytes: data, encoding: .utf8)
					print("data \(dataString)")
					let json = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.mutableContainers])
					print("json \(json)")
					if let val = json as? T {
						return val
					}
				}
				catch _ {}
				let decoder = JSONDecoder()
				return try? decoder.decode(T.self, from: data)
			}
			return nil

		}
	}

}
