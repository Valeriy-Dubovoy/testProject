//
//  WebModel.swift
//  testProject
//
//  Created by Valery Dubovoy on 19.10.2021.
//

import Foundation
import SwiftUI

class WebModel: ObservableObject {
    @Published var isError = false
    @Published var errorString: String?
    @Published var isAuthorized = false
    
    @Published var userName = "demo"
    @Published var password = "12345"
    
    @Published var paymentsList: [PaymentItem] = []

    private var baseURL = "http://82.202.204.94/api-test/"
    private var token = "" {
        didSet{
            getPaymentsList()
        }
    }


    //MARK: Common methods
    private func startLoad(withRequest request: URLRequest, completionHandler: @escaping (Data?, URLResponse?) -> Void, errorHandler: @escaping (String?)->Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                DispatchQueue.main.async {errorHandler(err.localizedDescription)}
                return
            }
            if let httpResponse = response as? HTTPURLResponse{
                guard (200...299).contains(httpResponse.statusCode) else {
                        
                        DispatchQueue.main.async {
                            errorHandler("Status code \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
                        }
                    return
                }
                print("response type \(String(describing: httpResponse.mimeType))")
                if let mimeType = httpResponse.mimeType, mimeType == "text/html",
                    let data = data {
                    DispatchQueue.main.async {
                        completionHandler(data, httpResponse)
                    }
                } else {
                    errorHandler("Incorrect data")
                }

            } else {
                errorHandler("Unknown error")
            }
        }
        task.resume()
    }

    private func getRequest(url: URL)->URLRequest{
        var request = URLRequest(url: url)
        
        request.addValue("12345", forHTTPHeaderField: "app-key")
        request.addValue("1", forHTTPHeaderField: "v")
        
        return request
    }
    
    private func setError(errorMessage: String) {
        self.isError = true
        self.errorString = errorMessage
    }
    
    //MARK: Login screen
    
    func doLogin()
    {
        isError = false
        token = ""
        isAuthorized = false
        
        if let requestURL = URL(string: baseURL + "login") {
            let postBodyString = "login=\(userName)&password=\(password)"
            //print(postBodyString)
            
            let postBodyData = postBodyString.data(using: .utf8)
            
            var request = getRequest(url: requestURL)
            request.httpMethod = "POST"
            request.httpBody = postBodyData

            startLoad(withRequest: request) { [self] data, response in
                self.readLoginAnswer( messageData: data )
            } errorHandler: { message in
                self.setError(errorMessage: message ?? "unknown error")
                print("ERROR: \(message ?? "?error message?")")
            }

        } else {
            self.setError(errorMessage: "URL not found")
        }
    }
    
    private func readLoginAnswer(messageData: Data?){
        if let data = messageData, let stringData = String(data: data, encoding: .utf8){
            print(stringData)
            
            do{
                let answer = try JSONDecoder().decode(LoginResponceStructure.self, from: data)
                if answer.success == "true" {
                    if let val = answer.response?["token"] {
                        self.token = val
                        //print("token=\(self.token)")
                    }
                } else {
                    setError(errorMessage: answer.error?.error_msg ?? "somr error" )
                }

            } catch {
                setError(errorMessage: error.localizedDescription)
            }
        } else {
            setError(errorMessage: "No data in the answer")
        }
    }
    
    //MARK: Get payments list
    func getPaymentsList() {
        isError = false
        
        //let URLString = "\(self.baseURL)payments?token=\"\(self.token)\""
        let URLString = "\(self.baseURL)payments?token=\(self.token)"
        print(URLString)
        if let requestURL = URL(string: URLString) {
            
            var request = getRequest(url: requestURL)
            request.httpMethod = "GET"

            startLoad(withRequest: request) { [self] data, response in
                self.readPaymentsList( messageData: data )
            } errorHandler: { message in
                self.setError(errorMessage: message ?? "unknown error")
                print("ERROR: \(message ?? "?error message?")")
            }

        } else {
            self.setError(errorMessage: "URL not found")
        }
    }

    private func readPaymentsList(messageData: Data?){
        if let data = messageData, let stringData = String(data: data, encoding: .utf8){
            print(stringData)
            
            do{
                let answer = try JSONDecoder().decode(PaymentsResponceStructure.self, from: data) as PaymentsResponceStructure
                if answer.success == "true" {
                    if let val = answer.response {
                        paymentsList = val
                        isAuthorized = true
                    }
                    else {
                        paymentsList = []
                    }
                } else {
                    setError(errorMessage: answer.error?.error_msg ?? "somr error" )
                }

            } catch {
                setError(errorMessage: "Read the list error: \(error.localizedDescription)")
            }
            
 
        } else {
            setError(errorMessage: "No data in the answer")
        }

    }
}

//MARK: Structures

struct LoginResponceStructure : Decodable {
    let success: String
    let error: ErrorStructure?
    let response : [String:String]?
}

struct PaymentsResponceStructure : Decodable {
    let success: String
    let error: ErrorStructure?
    let response : [PaymentItem]?
}

struct ErrorStructure : Decodable {
    let error_code: Int
    let error_msg: String
}

struct PaymentItem : Decodable, Identifiable, Hashable {
    let description: String?
    let amount: String?
    var currency: String?
    var created: Int?
    
    let id = UUID()

    enum CodingKeys: String, CodingKey {
        case description = "desc"
        case amount
        case currency
        case created
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        description = try? values.decode(String.self, forKey: .description)
        currency = try? values.decode(String.self, forKey: .currency)
        
        if let value = try? values.decode(Double.self, forKey: .amount) {
            amount = String( value )
        } else if let value = try? values.decode(String.self, forKey: .amount) {
            amount = value
        } else if let value = try? values.decode(Int.self, forKey: .amount) {
            amount = String(value)
        } else {
            amount = ""
        }
        
        if let value = try? values.decode(Int.self, forKey: .created) {
            created = value
        } else if let value = try? values.decode(String.self, forKey: .amount) {
            created = Int( value )
        } else {
            created = nil
        }
    }
}


