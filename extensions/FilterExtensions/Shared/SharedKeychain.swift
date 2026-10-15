import Foundation
import Security

/// Shared keychain group wiring. Milestone 1 does not read or write items.
public enum SharedKeychain {
    /// Full access group once Siu replaces the team-id placeholder.
    /// Entitlement form: $(AppIdentifierPrefix)group.uk.spng.ioscontentfilter
    /// Runtime form: TEAMID.group.uk.spng.ioscontentfilter
    public static func accessGroup(teamId: String) -> String {
        "\(teamId).\(FilterConstants.keychainAccessGroupSuffix)"
    }

    public static func query(account: String, teamId: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: FilterConstants.keychainService,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup(teamId: teamId),
        ]
    }
}
