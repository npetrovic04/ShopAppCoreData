//
//  Apollo.swift
//  ProbaDruga
//
//  Created by Jola on 13.6.22..
//

import Foundation
import Apollo


class ApolloManager {
    static let shared = ApolloManager()
    
    // 2
    var client: ApolloClient = ApolloClient(url: URL(string: "https://crestview.joladev.com/graphql")!)
    
    // 3
    init() {
        self.setClient()
    }
    
    func setClient() {
        let cache = InMemoryNormalizedCache()
        let store1 = ApolloStore(cache: cache)
        let configuration = URLSessionConfiguration.default
        
        if CustomUserDefaults.isCustomerLoggedIn() {
            let token = CustomUserDefaults.getUserAccessToken()
            let authPayloads = ["Authorization": "Bearer \(token!)"]
            configuration.httpAdditionalHeaders = authPayloads
        }
        
        let client1 = URLSessionClient(sessionConfiguration: configuration, callbackQueue: nil)
        let provider = NetworkInterceptorProvider(client: client1, shouldInvalidateClientOnDeinit: true, store: store1)
        
        let url = URL(string: "https://crestview.joladev.com/graphql")!
        
        let requestChainTransport = RequestChainNetworkTransport(interceptorProvider: provider,
                                                                 endpointURL: url)
        
        client = ApolloClient(networkTransport: requestChainTransport,
                            store: store1)
    }
}

class NetworkInterceptorProvider: DefaultInterceptorProvider {
    override func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(CustomInterceptor(), at: 0)
        return interceptors
    }
}

class CustomInterceptor: ApolloInterceptor {
    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Swift.Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
            
        if CustomUserDefaults.isCustomerLoggedIn() {
            let token = CustomUserDefaults.getUserAccessToken()
            request.addHeader(name: "Authorization", value: "Bearer \(token!)")
        }
            
        print("request :\(request)")
        print("response :\(String(describing: response))")
        
        chain.proceedAsync(request: request,
                           response: response,
                           completion: completion)
    }
}
