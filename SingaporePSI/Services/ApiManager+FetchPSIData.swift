//
//  ApiManager+FetchPSIData.swift
//  SingaporePSI
//
//  Created by wiraone on 31/10/17.
//  Copyright © 2017 Wirawan. All rights reserved.
//

import Foundation
import Alamofire
import Gloss

extension APIManager {
    // MARK: Fetch API
    
    func fetchPSIData(param: InputForm, completion: @escaping (_ result: PSIData?, _ error: PSIErrorHandler?) -> ()) -> Request {
        let router = PSIRouter(endpoint: PSIEndpoint.fetchData(param: param))
        
        //validate codes including those from API for custom errors
        return manager.request(router)
            .validate()
            .responseJSON(completionHandler: {
                (response) -> Void in
                
                if let statusCode: Int = (response.response?.statusCode) {
                    switch statusCode {
                    case 200 ... 299:

                        if let value = response.result.value as? JSON {
                            let data = PSIData.init(json: value)
                            
                            if let _ = data?.fault?.faultString?.isEmpty {
                                completion(data, nil)
                            }
                            else {
                                let errorHandler = PSIErrorHandler.init()
                                errorHandler.errorCode = AppConstant.API.Error.Code.internalServerError
                                errorHandler.errorMessage = AppConstant.API.Error.Message.internalServerError
                                completion(nil, errorHandler)
                            }
                        }
                        else{
                            let error = PSIErrorHandler.init()
                            completion(nil, error)
                        }
                    case 400 ... 403:
                        //handle custom error on completion
                        let errorHandler = PSIErrorHandler.init()
                        errorHandler.errorCode = statusCode
                        
                        if statusCode == AppConstant.API.Error.Code.badRequest {
                            
                            if let value = response.result.value as? JSON {
                                errorHandler.errorMessage = value[AppConstant.JSONKey.Error.message] as? String
                            }
                        }
                        completion(nil, errorHandler)
                    default:
                        let errorHandler = PSIErrorHandler.init()
                        errorHandler.errorCode = statusCode
                        errorHandler.errorMessage = AppConstant.API.Error.Message.internalServerError
                        completion(nil, errorHandler)
                    }
                }
                else {
                    if let error = response.result.error {
                        let errorHandler = PSIErrorHandler.init(with: error)
                        completion(nil, errorHandler)
                    }
                }
            })
    }
}
