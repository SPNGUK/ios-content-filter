namespace IosContentFilter;

/// <summary>
/// Bundle identifiers shared with the Swift extensions.
/// The canonical copy is shared/identity.props. scripts/check-identity.py keeps them aligned.
/// </summary>
public static class FilterIdentity
{
    public const string HostBundleId = "uk.spng.ioscontentfilter";
    public const string FilterDataBundleId = "uk.spng.ioscontentfilter.FilterData";
    public const string FilterControlBundleId = "uk.spng.ioscontentfilter.FilterControl";
    public const string AppGroupId = "group.uk.spng.ioscontentfilter";
    public const string KeychainAccessGroupSuffix = "group.uk.spng.ioscontentfilter";

    /// <summary>
    /// Replace with the 10-character Apple Team ID before using the shared keychain.
    /// The signed keychain group is TeamID + "." + <see cref="KeychainAccessGroupSuffix"/>.
    /// </summary>
    public const string TeamIdPlaceholder = "YOUR_TEAM_ID";

    public const string RulesFileName = "rules.json";
}
