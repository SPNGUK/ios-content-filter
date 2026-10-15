import Foundation
import NetworkExtension
import os

public enum FlowDecision: String, Sendable {
    case allow
    case drop
}

/// Per-flow decision used by FilterDataProvider.
public enum FlowEvaluator {
    private static let log = Logger(subsystem: FilterConstants.filterDataBundleId, category: "evaluate")

    /// HOOK: custom per-URL / per-flow logic belongs in this function.
    ///
    /// Milestone 1 logs a host-only description, reads the App Group rules file
    /// when it is present, and returns `.allow`. Return `.drop` to block the flow.
    /// The full URL is on `NEFilterBrowserFlow.url` for the code that replaces this body.
    public static func decide(_ flow: NEFilterFlow) -> FlowDecision {
        let rules = RuleStore.load()
        let subject = describe(flow)
        let version = rules?.version ?? -1
        log.info("flow subject=\(subject, privacy: .public) rulesVersion=\(version, privacy: .public)")
        _ = SharedKeychain.accessGroup(teamId: FilterConstants.teamIdPlaceholder)
        return .allow
    }

    private static func describe(_ flow: NEFilterFlow) -> String {
        if let browser = flow as? NEFilterBrowserFlow {
            if let url = browser.url, let host = url.host {
                let scheme = url.scheme ?? "url"
                return "\(scheme)://\(host)"
            }
            return "browser"
        }

        if let socket = flow as? NEFilterSocketFlow {
            if let hostname = socket.remoteHostname, !hostname.isEmpty {
                return "socket:\(hostname)"
            }
            if let endpoint = socket.remoteEndpoint {
                return "socket:\(String(describing: endpoint))"
            }
            return "socket"
        }

        return "flow"
    }
}
