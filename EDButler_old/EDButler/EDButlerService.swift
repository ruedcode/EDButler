//
//  EDButlerService.swift
//  EDButler
//
//  Created by Eugene Kalyada on 26.09.17.
//  Copyright © 2017 Edcode. All rights reserved.
//

import UIKit

open class EDButlerRequest:NSObject, URLSessionDelegate, URLSessionDataDelegate {

	public var route : EDButlerRoute
	fileprivate var session: URLSession

	fileprivate init(route: EDButlerRoute, sessionConfig:URLSessionConfiguration) {
		self.route = route
		session = URLSession(configuration: sessionConfig)
//		self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
	}

	public func run<T>(_ completion: @escaping ((EDButlerResponse<T>) -> Void)) {
		sendRequest { (data, response, error) in
			let object = EDButlerResponse<T>(data: data, response: response, error: error)
			completion(object)
		}
	}

	public func run() {
		sendRequest { (_, _, _) in}
	}

	fileprivate func sendRequest(completion: @escaping ((Data?, URLResponse?, Error?)->Void)) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		session.dataTask(with: route.request) { (data, response, error) in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			completion(data, response, error)
		}
	}

//
//	// MARK: - SessionDelegate
//	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//		<#code#>
//	}
//
//	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//		<#code#>
//	}

}

open class EDButlerService {

	open static let `default` = EDButlerService()
	fileprivate var sessionConfig: URLSessionConfiguration

	public init() {
		sessionConfig = URLSessionConfiguration.default
	}

	public init(sessionConfiguration: URLSessionConfiguration) {
		self.sessionConfig = sessionConfiguration
	}

	public func load(_ route: EDButlerRoute)->EDButlerRequest {
		return EDButlerRequest(route: route, sessionConfig: sessionConfig)
	}

}
