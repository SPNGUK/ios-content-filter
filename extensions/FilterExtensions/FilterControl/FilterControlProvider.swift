import NetworkExtension
import os

/// Control-plane provider. Handles flows the data provider passes upward
/// (for example after a `.needRules()` verdict) and is the place rule updates
/// will be applied. Milestone 1 allows the flow and does not push new rules.
public final class FilterControlProvider: NEFilterControlProvider {
    private let log = Logger(subsystem: FilterConstants.filterControlBundleId, category: "control")

    override public func startFilter(completionHandler: @escaping (Error?) -> Void) {
        log.info("startFilter")
        completionHandler(nil)
    }

    override public func stopFilter(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        log.info("stopFilter reason=\(reason.rawValue, privacy: .public)")
        completionHandler()
    }

    override public func handleNewFlow(
        _ flow: NEFilterFlow,
        completionHandler: @escaping (NEFilterControlVerdict) -> Void
    ) {
        let version = RuleStore.load()?.version ?? -1
        let subject = String(describing: type(of: flow))
        log.info("control flow type=\(subject, privacy: .public) rulesVersion=\(version, privacy: .public)")
        completionHandler(.allow(withUpdateRules: false))
    }
}
