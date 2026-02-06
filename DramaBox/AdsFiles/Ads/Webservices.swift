//
//  Webservices.swift
//  Best Quotes & Status
//
//  Created by ICON on 23/10/18.
//  Copyright © 2018 Gravity Infotech. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import Alamofire
import SwiftyJSON
import MBProgressHUD

let reachability = Reachability()!

class WebServices: NSObject
{
    var operationQueue = OperationQueue()
    
    func CallGlobalAPI(url:String, headers:[String:String], parameters:NSDictionary, httpMethod:String, progressView:Bool, uiView:UIView, networkAlert:Bool, responseDict:@escaping (_ jsonResponce:JSON?, _ strErrorMessage:String) -> Void) {
        
        print("httpMethod: \(httpMethod)")
        print("URL: \(url)")
        print("Headers: \n\(headers)")
        print("Parameters: \n\(parameters)")

        if progressView == true {
        self.ProgressViewShow(uiView:uiView)
        }
        let operation = BlockOperation.init
        {
            DispatchQueue.global(qos: .background).async
            {
                if self.internetChecker(reachability: Reachability()!) {
                    if (httpMethod == "POST") {
                        var req = URLRequest(url: try! url.asURL())
                        req.httpMethod = "POST"
                        req.allHTTPHeaderFields = headers as? [String:String]
                        req.setValue("application/json", forHTTPHeaderField: "content-type")
                        req.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
                        req.timeoutInterval = 30
                        AF.request(req).responseJSON { response in
                            switch (response.result)
                            {
                            case .success:
                                if((response.value) != nil)
                                {
                                    if response.response?.statusCode == 200
                                    {
                                        let jsonResponce = JSON(response.value!)
                                        print("Responce: \n\(jsonResponce)")
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict(jsonResponce,"")
                                        }
                                    }
                                    else if response.response?.statusCode == 403
                                    {
                                        let jsonResponce = JSON(response.value!)
                                        print("Responce: status 403 \n\(jsonResponce)")
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict(jsonResponce,"")
                                            showAlertMsg(Message: "\(jsonResponce["message"].stringValue)", AutoHide: false)
                                        }
                                    }
                                    else if response.response?.statusCode == 400
                                    {
                                        let jsonResponce = JSON(response.value!)
                                        print("Responce: status 403 \n\(jsonResponce)")
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict(jsonResponce,"")
                                            showAlertMsg(Message: "\(jsonResponce["message"].stringValue)", AutoHide: false)
                                        }
                                    }
                                    else
                                    {
                                        DispatchQueue.main.async {
                                            let jsonResponce = JSON(response.value!)
                                            print("Responce: other status \n\(jsonResponce)")
                                            self.ProgressViewHide(uiView: uiView)
                                            showAlertMsg(Message: "Something Went Wrong Server Problem..Try Again", AutoHide: false)
                                        }
                                    }
                                }
                                break
                            case .failure(let error):
                                let message : String
                                if let httpStatusCode = response.response?.statusCode {
                                    print("httpStatusCode: \n\(httpStatusCode)")
                                    switch(httpStatusCode) {
                                    case 400:
                                        message = "Something Went Wrong..Try Again"
                                    case 401:
                                        message = "Something Went Wrong..Try Again"
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict([:],message)
                                        }
                                    default: break
                                    }
                                } else {
                                    message = error.localizedDescription
                                    let jsonError = JSON(response.error!)
                                    DispatchQueue.main.async {
                                        self.ProgressViewHide(uiView: uiView)
                                        responseDict(jsonError,"Server issue")
                                    }
                                }
                                break
                            }
                        }
                    }
                    else if (httpMethod == "GET") {
                        
                        var req = URLRequest(url: try! url.asURL())
                        req.httpMethod = "GET"
                        req.allHTTPHeaderFields = headers as? [String:String]
                        req.setValue("application/json", forHTTPHeaderField: "content-type")
//                        req.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
                        req.timeoutInterval = 30
                        AF.request(req).responseJSON { response in
                            switch (response.result)
                            {
                            case .success:
                                
                                if((response.value) != nil) {
                                    
                                    if response.response?.statusCode == 200
                                    {
                                        let jsonResponce = JSON(response.value!)
                                        print("Responce: \n\(jsonResponce)")
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict(jsonResponce,"")
                                        }
                                    }
                                    else
                                    {
                                        DispatchQueue.main.async {
                                            let jsonResponce = JSON(response.value!)
                                            print("Responce: \n\(jsonResponce)")
                                            self.ProgressViewHide(uiView: uiView)
                                            showAlertMsg(Message: "Something Went Wrong Server Problem..Try Again", AutoHide: false)
                                        }
                                    }
                                }
                                break
                            case .failure(let error):
                                let message : String
                                if let httpStatusCode = response.response?.statusCode {
                                    switch(httpStatusCode) {
                                    case 400:
                                        message = "Something Went Wrong..Try Again"
                                    case 401:
                                        message = "Something Went Wrong..Try Again"
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict([:],message)
                                        }
                                    default: break
                                    }
                                } else {
                                    message = error.localizedDescription
                                    let jsonError = JSON(response.error!)
                                    DispatchQueue.main.async {
                                        self.ProgressViewHide(uiView: uiView)
                                        responseDict(jsonError,"Server issue")
                                    }
                                }
                                break
                            }
                        }
                    }
                    else if (httpMethod == "PUT") {
                        var req = URLRequest(url: try! url.asURL())
                        req.httpMethod = "PUT"
                        req.allHTTPHeaderFields = headers as? [String:String]
                        req.setValue("application/json", forHTTPHeaderField: "content-type")
                        req.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
                        req.timeoutInterval = 30
                        AF.request(req).responseJSON { response in
                            switch (response.result)
                            {
                            case .success:
                                if((response.value) != nil) {
                                    
                                    if response.response?.statusCode == 200
                                    {
                                        let jsonResponce = JSON(response.value!)
                                        print("Responce: \n\(jsonResponce)")
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict(jsonResponce,"")
                                        }
                                    }
                                    else
                                    {
                                        print("statuscode :- \(String(describing: response.response?.statusCode))")
                                        print("value :- \(String(describing: response.value))")
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            showAlertMsg(Message: "Something Went Wrong Server Problem..Try Again", AutoHide: false)
                                        }
                                    }
                                }
                                break
                            case .failure(let error):
                                let message : String
                                if let httpStatusCode = response.response?.statusCode {
                                    switch(httpStatusCode) {
                                    case 400:
                                        message = "Something Went Wrong..Try Again"
                                    case 401:
                                        message = "Something Went Wrong..Try Again"
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict([:],message)
                                        }
                                    default: break
                                    }
                                } else {
                                    message = error.localizedDescription
                                    let jsonError = JSON(response.error!)
                                    DispatchQueue.main.async {
                                        self.ProgressViewHide(uiView: uiView)
                                        responseDict(jsonError,"Server issue")
                                    }
                                }
                                break
                            }
                        }
                    }
                    else if (httpMethod == "DELETE") {
                        var req = URLRequest(url: try! url.asURL())
                        req.httpMethod = "DELETE"
                        req.allHTTPHeaderFields = headers as? [String:String]
                        req.setValue("application/json", forHTTPHeaderField: "content-type")
                        req.timeoutInterval = 30
                        AF.request(req).responseJSON { response in
                            print(response.result)
                            switch (response.result)
                            {
                            case .success:
                                if((response.value) != nil) {
                                    
                                    if response.response?.statusCode == 200
                                    {
                                        let jsonResponce = JSON(response.value!)
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict(jsonResponce,"")
                                        }
                                    }
                                    else
                                    {
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            showAlertMsg(Message: "Something Went Wrong Server Problem..Try Again", AutoHide: false)
                                        }
                                    }
                                }
                                break
                            case .failure(let error):
                                let message : String
                                if let httpStatusCode = response.response?.statusCode {
                                    switch(httpStatusCode) {
                                    case 400:
                                        message = "Something Went Wrong..Try Again"
                                    case 401:
                                        message = "Something Went Wrong..Try Again"
                                        DispatchQueue.main.async {
                                            self.ProgressViewHide(uiView: uiView)
                                            responseDict([:],message)
                                        }
                                    default: break
                                    }
                                } else {
                                    message = error.localizedDescription
                                    let jsonError = JSON(response.error!)
                                    DispatchQueue.main.async {
                                        self.ProgressViewHide(uiView: uiView)
                                        responseDict(jsonError,"Server issue")
                                    }
                                }
                                break
                            }
                        }
                    }
                }
                else
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.ProgressViewHide(uiView: uiView)
                        
                        if networkAlert == true
                        {
                            showAlertMessage(titleStr: "Error!", messageStr: MESSAGE_ERR_NETWORK)
                        }
                    }
                }
            }
        }
        operation.queuePriority = .normal
        operationQueue.addOperation(operation)
    }
    
    func multipartWebService(method:HTTPMethod, URLString:String, encoding:Alamofire.ParameterEncoding, parameters:[String: Any], fileData:Data!, fileUrl:URL?, headers:HTTPHeaders, keyName:String, completion: @escaping (_ response:AnyObject?, _ error: NSError?) -> ())
    {
        print("Fetching WS : \(URLString)")
        print("With parameters : \(parameters)")
        
        if  !NetworkReachabilityManager()!.isReachable {
            showAlertMessage(titleStr: "Error!", messageStr: MESSAGE_ERR_NETWORK)
            return
        }
        
        AF.upload(multipartFormData: { MultipartFormData in
            for (key, value) in parameters {
                MultipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            let name = randomString(length: 8)
            if let data = fileData{
                MultipartFormData.append(data, withName: keyName, fileName: "user_\(name).jpeg", mimeType: "image/jpeg")
            }
        }, to: URLString, method: method, headers: headers)
            .responseJSON { (response) in
                print(response.response?.statusCode)
                print(response.value)
                print("\(String(describing: response.data))")
                print(response.error)
                print(response.result)

                if let statusCode = response.response?.statusCode
                {
                    if  statusCode == HttpResponseStatusCode.noAuthorization.rawValue {
                        showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                        return
                    }
                }
                if let error = response.error
                {
                    completion(nil, error as NSError?)
                }
                else
                {
                    guard let data = response.data
                        else {
                            showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                            return
                    }
                    do {
                        let unparsedObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
                        completion(unparsedObject, nil)
                    }
                    catch let exception as NSError {
                        completion(nil, exception)
                    }
                }
        }
    }
    
    func multipartWebServiceDualImage(method:HTTPMethod, URLString:String, encoding:Alamofire.ParameterEncoding, parameters:[String: Any], fileData:Data!, SecondfileData:Data!, fileUrl:URL?, headers:HTTPHeaders, keyName:String, SecondkeyName:String, completion: @escaping (_ response:AnyObject?, _ error: NSError?) -> ())
    {
        print("Fetching WS : \(URLString)")
        print("With parameters : \(parameters)")
        
        if  !NetworkReachabilityManager()!.isReachable {
            showAlertMessage(titleStr: "Error!", messageStr: MESSAGE_ERR_NETWORK)
            return
        }
        
        AF.upload(multipartFormData: { MultipartFormData in
            for (key, value) in parameters {
                MultipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            let name = randomString(length: 8)
            if let data = fileData{
                MultipartFormData.append(data, withName: keyName, fileName: "user_\(name).jpeg", mimeType: "image/jpeg")
            }
            if let data2 = SecondfileData{
                MultipartFormData.append(data2, withName: SecondkeyName, fileName: "user_\(name).jpeg", mimeType: "image/jpeg")
            }
        }, to: URLString, method: method, headers: headers)
            .responseJSON { (response) in
                print(response.response?.statusCode)
                print(response.value)
                print("\(String(describing: response.data))")
                print(response.error)
                print(response.result)

                if let statusCode = response.response?.statusCode
                {
                    if  statusCode == HttpResponseStatusCode.noAuthorization.rawValue {
                        showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                        return
                    }
                }
                if let error = response.error
                {
                    completion(nil, error as NSError?)
                }
                else
                {
                    guard let data = response.data
                        else {
                            showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                            return
                    }
                    do {
                        let unparsedObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
                        completion(unparsedObject, nil)
                    }
                    catch let exception as NSError {
                        completion(nil, exception)
                    }
                }
        }
    }

    func multipartWebServiceArray(method:HTTPMethod, URLString:String, encoding:Alamofire.ParameterEncoding, parameters:[String: Any], fileData:[Data], fileUrl:URL?, headers:HTTPHeaders, keyName:String, completion: @escaping (_ response:AnyObject?, _ error: NSError?) -> ()){
        
        print("Fetching WS : \(URLString)")
        print("Headers: \n\(headers)")
        print("With parameters : \(parameters)")
        
        if  !NetworkReachabilityManager()!.isReachable {
            showAlertMessage(titleStr: "Error!", messageStr: MESSAGE_ERR_NETWORK)
            return
        }
        
        AF.upload(multipartFormData: { MultipartFormData in
            
            for (key, value) in parameters {
                MultipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            
            for data in fileData {
                let name = randomString(length: 8)
                MultipartFormData.append(data, withName: keyName, fileName: "product_\(name).jpeg", mimeType: "image/jpeg")
            }

        }, to: URLString, method: method, headers: headers)
        .responseJSON { (response) in
            print(response.result)
            if let statusCode = response.response?.statusCode {
                if  statusCode == HttpResponseStatusCode.noAuthorization.rawValue {
                    showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                    return
                }
            }
            if let error = response.error {
                completion(nil, error as NSError?)
            }
            else {
                guard let data = response.data
                else {
                    showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                    return
                }
                do {
                    let unparsedObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
                    completion(unparsedObject, nil)
                }
                catch let exception as NSError {
                    completion(nil, exception)
                }
            }
        }
    }
    
    func multipartImageVideoWebServiceArray(method:HTTPMethod, URLString:String, encoding:Alamofire.ParameterEncoding, parameters:[String: Any], fileData:[Data], fileUrl:URL?, headers:HTTPHeaders, uploadType:Int, keyName:String, videoName:String, completion: @escaping (_ response:AnyObject?, _ error: NSError?) -> ()){
        
        print("Fetching WS : \(URLString)")
        print("Headers: \n\(headers)")
        print("With parameters : \(parameters)")
        
        if  !NetworkReachabilityManager()!.isReachable {
            showAlertMessage(titleStr: "Error!", messageStr: MESSAGE_ERR_NETWORK)
            return
        }
        
        AF.upload(multipartFormData: { MultipartFormData in
            
            for (key, value) in parameters {
                MultipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            
            for data in fileData {
                let name = randomString(length: 8)
                MultipartFormData.append(data, withName: keyName, fileName: "product_\(name).jpeg", mimeType: "image/jpeg")
            }

            if let url = fileUrl {
                MultipartFormData.append(url as URL, withName: videoName)
            }

//            for data in fileData {
//                let name = randomString(length: 8)
//                MultipartFormData.append(data, withName: "thumbnail", fileName: "thumbnail_\(name).jpeg", mimeType: "image/jpeg")
//            }

//            if uploadType == 0
//            {
//                for data in fileData {
//                    let name = randomString(length: 8)
//                    MultipartFormData.append(data, withName: keyName, fileName: "product_\(name).jpeg", mimeType: "image/jpeg")
//                }
//            }
//            else
//            {
//                if let url = fileUrl {
//                    MultipartFormData.append(url as URL, withName: keyName)
//                }
//
//                for data in fileData {
//                    let name = randomString(length: 8)
//                    MultipartFormData.append(data, withName: "thumbnail", fileName: "thumbnail_\(name).jpeg", mimeType: "image/jpeg")
//                }
//            }
            
        }, to: URLString, method: method, headers: headers)
        .responseJSON { (response) in
            print(response.result)
            if let statusCode = response.response?.statusCode {
                if  statusCode == HttpResponseStatusCode.noAuthorization.rawValue {
                    showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                    return
                }
            }
            if let error = response.error {
                completion(nil, error as NSError?)
            }
            else {
                guard let data = response.data
                else {
                    showAlertMessage(titleStr: "Error!", messageStr: "Something went wrong.. Try again.")
                    return
                }
                do {
                    let unparsedObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
                    completion(unparsedObject, nil)
                }
                catch let exception as NSError {
                    completion(nil, exception)
                }
            }
        }
    }

    func internetChecker(reachability: Reachability) -> Bool {
        var check:Bool = false
        if reachability.connection == .wifi {
            check = true
        }
        else if reachability.connection == .cellular {
            check = true
        }
        else {
            check = false
        }
        return check
    }
    
    func ProgressViewShow(uiView:UIView) {
        
//        let secondViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoaderVC") as! LoaderVC
//        secondViewController.modalTransitionStyle = .crossDissolve
//        secondViewController.modalPresentationStyle = .overFullScreen
//        UIApplication.shared.windows[0].rootViewController?.present(secondViewController, animated: false, completion: nil)

        DispatchQueue.main.async {
            let Indicator = MBProgressHUD.showAdded(to: uiView, animated: true)
            Indicator.label.text = "Loading..."
            uiView.isUserInteractionEnabled = false
//            Indicator.detailsLabel.text = "fetching details"
            Indicator.show(animated: true)

//            MBProgressHUD.showAdded(to: uiView, animated: true)
//            SVProgressHUD.show(withStatus: "Loading...")
        }
    }
    
    func ProgressViewHide(uiView:UIView) {
        
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideloader"), object: nil)

        DispatchQueue.main.async {
            uiView.isUserInteractionEnabled = true
            MBProgressHUD.hide(for:uiView, animated: true)
//            SVProgressHUD.dismiss()
        }
    }
}
