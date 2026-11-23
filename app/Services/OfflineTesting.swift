//
//  OfflineTesting.swift
//  app
//
//  Walking the app with no network, on a simulator that cannot cut its
//  own. A debug build launched with -LVOffline YES fails every http and
//  https request the app's own sessions make, and URLSession.shared's,
//  as a phone with no signal does (URLError.notConnectedToInternet), so
//  every offline path (the bundled books, the kept copies, the "comes
//  with a connection" lines) can be seen. What it does not reach: the
//  system player streaming a recording (AVPlayer loads outside
//  URLSession) and the shelf's background downloads. Never in a release
//  build.
//

import Foundation

nonisolated enum OfflineTesting {

    static let isOn: Bool = {
        #if DEBUG
            return ProcessInfo.processInfo.arguments.contains("-LVOffline")
                || UserDefaults.standard.bool(forKey: "LVOffline")
        #else
            return false
        #endif
    }()

    /// At launch: URLSession.shared answers as offline too
    static func start() {
        if isOn { URLProtocol.registerClass(NoNetworkProtocol.self) }
    }
}

nonisolated extension URLSessionConfiguration {
    /// `.default`, for each of the app's sessions to start from: with no
    /// network under OfflineTesting
    static var app: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        if OfflineTesting.isOn {
            config.protocolClasses = [NoNetworkProtocol.self] + (config.protocolClasses ?? [])
        }
        return config
    }
}

/// Answers every web request as a phone with no signal would
nonisolated final class NoNetworkProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        ["http", "https"].contains(request.url?.scheme?.lowercased() ?? "")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}
