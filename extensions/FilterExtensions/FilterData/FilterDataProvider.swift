import NetworkExtension
import os

/// Data-plane content filter. The system calls `handleNewFlow` for each flow
/// that the installed `NEFilterSettings` send here.
public final class FilterDataProvider: NEFilterDataProvider {
    private let log = Logger(subsystem: FilterConstants.filterDataBundleId, category: "provider")

    override public func startFilter(completionHandler: @escaping (Error?) -> Void) {
        log.info("startFilter")
        // No NEFilterRule values yet, so .filterData delivers every new flow to handleNewFlow.
        // A later milestone should narrow this with explicit rules. The data provider
        // process has a small jetsam budget; keep the decision path tiny.
        let settings = NEFilterSettings(rules: [], defaultAction: .filterData)
        apply(settings) { error in
            completionHandler(error)
        }
    }

    override public func stopFilter(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        log.info("stopFilter reason=\(reason.rawValue, privacy: .public)")
        completionHandler()
    }

    override public func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        switch FlowEvaluator.decide(flow) {
        case .allow:
            return .allow()
        case .drop:
            return .drop()
        }
    }
}
