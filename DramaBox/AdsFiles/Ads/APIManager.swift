import Foundation
import SystemConfiguration
import Alamofire
import CoreMedia

struct API {
    
    static let Countries        = "https://iptv-org.github.io/api/countries.json"
    static let Categories       = "https://iptv-org.github.io/api/categories.json"
    static let Channels         = "https://iptv-org.github.io/api/channels.json"
    static let Streams          = "https://iptv-org.github.io/api/streams.json"
}

var COOKIE = "intercom-id-h3v14f8j=6ad7b0d4-68fc-4bbf-926d-cec72cf82c2e; intercom-device-id-h3v14f8j=8a0422ed-9bc9-4f78-bd77-aed57b4a63d9; __Host-next-auth.csrf-token=50896a1f3b8b65889203f032e4d41bf020e9639492f382fe5880463e0f7da994%7Cc63f1f98b495340ff5997810e209f8faeca2aaa6081e56108cfa4b0eadfcc275; __stripe_mid=767587e6-2d29-45bd-93c4-0aeef4ff96d1305ad0; __Secure-next-auth.callback-url=https%3A%2F%2Fplaygroundai.com%2Fcreate%3F; __Secure-next-auth.session-token=7152d431-e6b3-42d8-8c41-77d5c9ba7973; mp_6b1350e8b0f49e807d55acabb72f5739_mixpanel=%7B%22distinct_id%22%3A%20%22clf6ln8wm07z0s601xt7vg6wg%22%2C%22%24device_id%22%3A%20%22186da3796d8780-0544afa55355b-1b525635-240000-186da3796d9e5d%22%2C%22%24search_engine%22%3A%20%22google%22%2C%22%24initial_referrer%22%3A%20%22https%3A%2F%2Fwww.google.com%2F%22%2C%22%24initial_referring_domain%22%3A%20%22www.google.com%22%2C%22%24user_id%22%3A%20%22clf6ln8wm07z0s601xt7vg6wg%22%2C%22email%22%3A%20%22sagar.l%40jksol.com%22%7D; __stripe_sid=c7baf5d4-e96a-42fa-96e5-1010cfff98cd8dfaf1; intercom-session-h3v14f8j=NVhWWGxmdEdVc1p3SlJqR25MSXBCUGFEQnRucWFoR1pGelJPSmxwNFBMNFozelFObWFjdmkzaWZqUUIyTW9sQy0tY09pVE5odEtOQUZyQmVkbFZLVVhTQT09--e02619a73f80752bf38181f2a5bd9503688b20e4"

public class APIManager {
    
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    class func toJson(_ dict:[String:Any]) -> String {
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        return jsonString!
    }
    
    func networkErrorMsg() {
        showAlert("Error", message: "You are not connected to the internet") {}
    }
    
    // Session that allows invalid certificates
    /*private let insecureSession: Session = {
     let manager = ServerTrustManager(evaluators: ["api.themoviedb.org": DisabledTrustEvaluator()])
     let configuration = URLSessionConfiguration.default
     return Session(configuration: configuration, serverTrustManager: manager)
     }()*/
    
    func GET_DATA_API(api: String, header: HTTPHeaders, _ completion: @escaping (_ data: Data?) -> Void) {
        AF.request(api, method: .get, headers: header).responseData { response in
            switch response.result {
            case .success(let data):
                completion(data)
            case .failure(let error):
                displayToast(error.localizedDescription)
            }
        }
    }
    
    func GET_DATA_WITH_BODY_API(api: String, parameters: [String:Any],_ completion: @escaping (_ data: Data?) -> Void) {
        AF.request(api, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData { response in
            switch response.result {
            case .success(let data):
                completion(data)
            case .failure(let error):
                //showToast(message: error.localizedDescription)
                displayToast(error.localizedDescription)
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func GET_API(api: String, isShowLoader: Bool, _ completion: @escaping (_ data: Data?) -> Void) {
        if !APIManager.isConnectedToNetwork() {
            APIManager().networkErrorMsg()
            return
        }
        
     //   isShowLoader ? (showLoader()) : nil
        let headerParams = getJsonHeader()
        
        AF.request(api, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headerParams).responseData { response in
         //   isShowLoader ? (removeLoader()) : nil
            switch response.result {
                case .success(_):
                    if let data = response.data {
                        completion(data)
                        return
                    }
                    break
                
                case .failure(let error):
                   // displayToast(error.localizedDescription)
                    break
            }
        }
    }
    
    func getJsonHeader() -> HTTPHeaders {
        return ["X-RapidAPI-Host": "yt-api.p.rapidapi.com","X-RapidAPI-Key": "1656db373cmsh36dd76bfd7a6dfap1067d8jsn1810bbf77054"]
    }
}
