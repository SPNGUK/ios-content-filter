using NetworkExtension;

namespace IosContentFilter;

/// <summary>
/// Builds the configuration the host will eventually pass to NEFilterManager.
/// Milestone 1 does not call LoadFromPreferences or SaveToPreferences.
/// </summary>
public static class FilterConfigurationDraft
{
    public static string Describe()
    {
        using var configuration = new NEFilterProviderConfiguration
        {
            Organization = "SPNG",
            FilterBrowsers = true,
            FilterSockets = true,
        };

        var browsers = configuration.FilterBrowsers;
        var sockets = configuration.FilterSockets;
        return
            $"In-memory NEFilterProviderConfiguration organization={configuration.Organization}, filterBrowsers={browsers}, filterSockets={sockets}. " +
            $"Embedded providers: {FilterIdentity.FilterDataBundleId} and {FilterIdentity.FilterControlBundleId}. " +
            "On iOS the system selects those providers from the embedded appex bundles. " +
            "SaveToPreferences is left for a later milestone, after a signing identity exists. " +
            "A distribution-signed save succeeds on a supervised device, or on a Screen Time child device. " +
            "A development-signed save (get-task-allow) is the debugging path on an unsupervised iPad.";
    }
}
