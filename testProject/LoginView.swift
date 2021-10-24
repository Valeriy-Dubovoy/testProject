//
//  ContentView.swift
//  testProject
//
//  Created by Valery Dubovoy on 19.10.2021.
//

import SwiftUI

struct LoginView: View {
    //@State private var login = "demo"
    //@State private var password = "12345"
    
    @ObservedObject var webInterface = WebModel()

    var body: some View {

        NavigationView{
            
            if webInterface.isAuthorized {
                VStack{
                    List( webInterface.paymentsList ) {payment in
                        VStack{
                            Text(payment.description ?? "").font(SwiftUI.Font.title).padding()
                            HStack{
                                Text(payment.amount ?? "").padding(.leading)
                                Text(payment.currency ?? "").padding(.trailing)
                            }.font(.largeTitle).padding()
                            HStack {
                                Text("Created")
                                    .padding(.leading)
                                Text("\(payment.created ?? 0)")
                                    .padding(.trailing)
                            }.padding().font(SwiftUI.Font.subheadline)
                        }
                        
                    }
                        .navigationTitle("Payments")
                        .toolbar {
                            Button("Logout") {
                                webInterface.isAuthorized = false
                            }
                        }
                }
            } else {
                VStack{
                    HStack{
                        VStack{
                            Text("Login").padding()
                            Text("Password").padding()
                        }.padding()
                        
                        VStack{
                            TextField("Login", text: $webInterface.userName )
                                .padding()
                                .textContentType(.username)
                            SecureField("Password", text: $webInterface.password)
                                .padding()
                                .textContentType(/*@START_MENU_TOKEN@*/.password/*@END_MENU_TOKEN@*/)
                            
                        }.padding()
                    }
                    //NavigationLink(
                    Button("Logon") {
                        //print("Logon with \(login)/\(password)")
                        //self.webInterface.userName = login
                        //self.webInterface.password = password
                        self.webInterface.doLogin()
                    }
                    
                    if webInterface.isError {
                        Text(webInterface.errorString ?? "Unknown error")
                            .padding()
                            .foregroundColor(Color.red)
                    }
                }
                .navigationTitle("Authorization")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
