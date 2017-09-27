//
//  EDButlerEndpoint.swift
//  EDButler
//
//  Created by Eugene Kalyada on 26.09.17.
//  Copyright © 2017 Edcode. All rights reserved.
//

import UIKit

open class EDButlerRoute {

	enum EDButlerRouteError: Error {
		case emptyDefaultHost
	}

	//default host for requests
	open static var defaultHost: String?

	public enum EDButlerRouteMethod : String {
		case post = "POST"
		case get = "GET"
		case patch = "PATCH"
		case put = "PUT"
		case delete = "DELETE"
	}

	open var timeout : TimeInterval = 30
	open var host : String
	open var path : String
	open var params : [AnyHashable:Any]? {
		didSet {
			self.files = [:]
			if let params = params {
				files = params.filter({ (key, value) -> Bool in
					return value is UIImage || value is Data
				})
			}
		}
	}

	open var method : EDButlerRouteMethod
	open var asJSON : Bool = false

	fileprivate var hasFiles:Bool  {
		get {
			return files.count > 0
		}
	}

	fileprivate var files: [AnyHashable:Any] = [:]


	fileprivate var httpBody:Data? {
		get {
			let parameterData = urlEncodedParameters.data(using: .utf8)
			if parameterData == nil, fileData != nil {
				return fileData
			}
			if var parameterData = parameterData, let fileData = fileData {
				parameterData.append(fileData)
				return parameterData
			}
			return parameterData
		}
	}

	open var request: URLRequest {
		get {
			var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
			request.httpMethod = method.rawValue


			if asJSON {
				request.setValue("application/json", forHTTPHeaderField: "Content-type")
				if method != EDButlerRouteMethod.get, self.params != nil  {
					let jsonData = try! JSONSerialization.data(withJSONObject: self.params!, options:.prettyPrinted)
					request.httpBody = jsonData
				}
			}
			//as url Encoded
			else {
				if( method != EDButlerRouteMethod.get ) {
					request.httpBody = httpBody
				}
				if hasFiles {
					 request.setValue("multipart/form-data; boundary=Files", forHTTPHeaderField: "Content-type")
				}
			}

			return request
		}
	}

	fileprivate var url:URL {
		get {
			var baseURL = URL(string: host + path)!
			if( method == .get || method == .patch  ) {
				if( urlEncodedParameters.characters.count > 0 ) {
					let prefix = baseURL.query != nil ? "&" : "?"
					print("\( baseURL.absoluteString) \(prefix) \(urlEncodedParameters)")
					baseURL = URL(string: "\(baseURL.absoluteString)\(prefix)\(urlEncodedParameters)")!
				}
			}
			return baseURL
		}
	}

	fileprivate var urlEncodedParameters:String {
		get {
			var res = ""
			if let keys = params?.keys {
				var stringParameters : [String] = []
				for key in keys {
					let value = params![key] ?? ""
					var stringValue : String!
					if value is String {
						if let val = value as? String {
							stringValue = escapeValue(string: val)
						}
					}
					else {
						stringValue = escapeValue(string: "\(value)")
					}
					stringParameters.append("\(key)=\(stringValue)")
				}
				res = stringParameters.joined(separator: "&")
			}
			return res
		}
	}

	fileprivate var fileData: Data? {
		get {
			if hasFiles {
				var body = Data()
				for key in self.files.keys {
					let value = params![key]
					if value is UIImage  {
						if let imageData = UIImageJPEGRepresentation(value as! UIImage, 1) {
							body.append("\r\n--Files\r\n".data(using: String.Encoding.utf8)!)
							body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key).jpg\"\r\n".data(using: String.Encoding.utf8)!)
							body.append("Content-Type: image/jpeg\r\n\r\n".data(using: String.Encoding.utf8)!)
							body.append(imageData)
							body.append("\r\n".data(using: String.Encoding.utf8)!)
							body.append("--Files--\r\n".data(using: String.Encoding.utf8)!)
						}
					}
					else if let value = value as? Data {
						body.append(value)
					}
				}
				return body
			}
			return nil
		}
	}

	public init(host:String, method:EDButlerRouteMethod, path:String, asJSON: Bool, params:[AnyHashable:Any]?) {
		self.host = host
		self.method = method
		self.path = path
		self.asJSON = asJSON
		self.params = params
	}

	public init(method:EDButlerRouteMethod, path:String, asJSON: Bool, params:[AnyHashable:Any]?) throws {
		guard let host = EDButlerRoute.defaultHost else {
			throw EDButlerRouteError.emptyDefaultHost
		}
		self.host = host
		self.method = method
		self.path = path
		self.asJSON = asJSON
		self.params = params
	}

	public init(method:EDButlerRouteMethod, path:String, asJSON: Bool) throws {
		guard let host = EDButlerRoute.defaultHost else {
			throw EDButlerRouteError.emptyDefaultHost
		}
		self.host = host
		self.method = method
		self.path = path
		self.asJSON = asJSON
	}

	public init(method:EDButlerRouteMethod, path:String) throws {
		guard let host = EDButlerRoute.defaultHost else {
			throw EDButlerRouteError.emptyDefaultHost
		}
		self.host = host
		self.method = method
		self.path = path
	}

    private func escapeValue(string: Any) -> String {
		var res = ""
		if let string = string as? String {
			res = string
		}
		else {
			res = String(describing: string)
		}
        return res.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!

    }
}
