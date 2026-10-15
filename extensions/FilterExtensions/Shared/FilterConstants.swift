import Foundation

/// Identifiers shared with the MAUI host. Keep in sync with shared/identity.props.
public enum FilterConstants {
    public static let hostBundleId = "uk.spng.ioscontentfilter"
    public static let filterDataBundleId = "uk.spng.ioscontentfilter.FilterData"
    public static let filterControlBundleId = "uk.spng.ioscontentfilter.FilterControl"
    public static let appGroupId = "group.uk.spng.ioscontentfilter"
    /// Suffix after $(AppIdentifierPrefix) / the Team ID.
    public static let keychainAccessGroupSuffix = "group.uk.spng.ioscontentfilter"
    /// Replace with the Apple Team ID before any keychain call. See README.md.
    public static let teamIdPlaceholder = "YOUR_TEAM_ID"
    public static let rulesFileName = "rules.json"
    public static let keychainService = "uk.spng.ioscontentfilter.shared"
}
