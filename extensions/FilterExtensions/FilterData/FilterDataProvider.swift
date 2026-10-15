import NetworkExtension
import os

/// Data-plane content filter. The system calls `handleNewFlow` for each flow
/// that the installed `NEFilterSettings` send here.
public final class FilterDataProvider: NEFilterDataProvider {
    private let log = Logger(subsystem: FilterConstants.filterDataBundleId, category: "provider")

    override public func startFilter(completionHandler: @escaping (Error?) -> Void) {
        log.info("startFilter")
        // NEFilterSettings and apply(_:) are macOS-only. On iOS the system delivers
        // flows to handleNewFlow from the provider configuration the host saves
        // (filterBrowsers / filterSockets). Keep this path small: the data provider
        // process has a tight jetsam budget.
        completionHandler(nil)
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
