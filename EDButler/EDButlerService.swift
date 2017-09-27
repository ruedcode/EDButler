//
//  EDButlerService.swift
//  EDButler
//
//  Created by Eugene Kalyada on 26.09.17.
//  Copyright © 2017 Edcode. All rights reserved.
//

import UIKit

open class EDButlerRequest:NSObject {

	public enum EDButlerRequestError: Error {
		case badRequest
		case forbidden
		case unauthorized
		case internalServerError
		case unknown
	}

	public var route : EDButlerRoute
	public var expectedContentLength: Int64 = 0
	public var downloadedContentLength: Int = 0
	public var downloadedData: Data?
	public var didChangedProgress : (()->Void)?
	public var willPerform : ((URLRequest)->URLRequest)?

	weak fileprivate var service: EDButlerService?


	fileprivate init(route: EDButlerRoute, service:EDButlerService) {
		self.route = route
		self.service = service
	}

	public func run<T>(type: T.Type, completion: @escaping ((EDButlerResponse<T>) -> Void)) {
		service?.sendRequest(self, completion: { (data, response, error) in
			let object = EDButlerResponse<T>(data: data, response: response, error: error)
			completion(object)
		})
	}

	public func run() {
		service?.sendRequest(self, completion: { (_, _, _) in})
	}

	static fileprivate func error(for statusCode: Int) -> Error {
		let errors = [
			400: EDButlerRequestError.badRequest,
			401: EDButlerRequestError.unauthorized,
			403: EDButlerRequestError.forbidden,
			500: EDButlerRequestError.internalServerError,
		]
		var res = EDButlerRequestError.unknown
		if let type = errors[statusCode] {
			res = type
		}
		return res
	}
}

open class EDButlerService: NSObject, URLSessionTaskDelegate, URLSessionDelegate, URLSessionDataDelegate {

	open static let `default` = EDButlerService()

	open static var willPerform : ((URLRequest)->URLRequest)?

	fileprivate var sessionConfiguration: URLSessionConfiguration
	fileprivate var runnedDataTasks: [URLSessionDataTask:EDButlerRequest] = [:]

	lazy fileprivate var session: URLSession = {
		let session = URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: nil)
		return session
	}()

	public override init() {
		sessionConfiguration = URLSessionConfiguration.default
	}

	public init(sessionConfiguration: URLSessionConfiguration) {
		self.sessionConfiguration = sessionConfiguration
	}

	public func load(_ route: EDButlerRoute)->EDButlerRequest {
		return EDButlerRequest(route: route, service: self)
	}

	public func cancellAll() {
		for item in runnedDataTasks {
			item.key.cancel()
		}
		runnedDataTasks = [:]
	}

	public func cancel(_ request: EDButlerRequest) {
		if let item = runnedDataTasks.filter({ (item) -> Bool in
			return item.value == request
		}).first {
			item.key.cancel()
		}
	}

	fileprivate func sendRequest(_ request: EDButlerRequest, completion: @escaping ((Data?, URLResponse?, Error?)->Void)) {
		//run globall modification
		var urlRequest = request.route.request
		if let globalModification = EDButlerService.willPerform {
			urlRequest = globalModification(urlRequest)
		}
		if let localModification = request.willPerform {
			urlRequest = localModification(urlRequest)
		}
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		let task = session.dataTask(with: urlRequest) {[weak self] (data, response, error) in
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				self?.parseResponse(data: data, response: response, error: error, completion: completion)

			}

		}
		runnedDataTasks[task] = request
		task.resume()
	}

	private func parseResponse(data: Data?, response:URLResponse?, error: Error?, completion: @escaping ((Data?, URLResponse?, Error?)->Void)) {
		var error = error
		if error == nil, let httpResponse = response as? HTTPURLResponse {
			if httpResponse.statusCode != 200 {
				error = EDButlerRequest.error(for: httpResponse.statusCode)
			}
		}
		completion(data, response, error)
	}

	// MARK: - URLSession
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		if let request = runnedDataTasks[dataTask] {
			request.expectedContentLength = response.expectedContentLength
			request.downloadedData = Data()
			request.downloadedContentLength = 0
			if let action = request.didChangedProgress {
				action()
			}
		}
	}

	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		if let request = runnedDataTasks[dataTask] {
			request.downloadedData?.append(data)
			request.downloadedContentLength = request.downloadedData!.count
		}
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let task = task as? URLSessionDataTask {
			runnedDataTasks.removeValue(forKey: task)
		}
	}


}
