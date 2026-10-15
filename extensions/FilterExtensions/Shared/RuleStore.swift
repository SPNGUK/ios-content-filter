import Foundation
import os

public struct FilterRules: Decodable, Sendable {
    public var version: Int
    public var defaultDecision: String
}

/// Reads rules.json from the App Group container. The host is the writer.
public enum RuleStore {
    private static let log = Logger(subsystem: FilterConstants.hostBundleId, category: "rules")

    public static func load() -> FilterRules? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: FilterConstants.appGroupId
        ) else {
            log.error("App Group container is unavailable for \(FilterConstants.appGroupId, privacy: .public)")
            return nil
        }

        let url = container.appendingPathComponent(FilterConstants.rulesFileName)
        guard let data = try? Data(contentsOf: url) else {
            log.info("No rules file yet")
            return nil
        }

        do {
            return try JSONDecoder().decode(FilterRules.self, from: data)
        } catch {
            log.error("Could not decode rules.json: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
