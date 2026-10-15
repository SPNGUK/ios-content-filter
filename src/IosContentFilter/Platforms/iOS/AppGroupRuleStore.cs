namespace IosContentFilter;

/// <summary>
/// Writes the sample rules document into the App Group container.
/// Returns null from the container API when the App Group entitlement is not on the signature.
/// </summary>
public static class AppGroupRuleStore
{
    public const string PackagedRulesName = "rules.sample.json";

    public static async Task<string> WriteSampleAsync()
    {
        using var packaged = await FileSystem.OpenAppPackageFileAsync(PackagedRulesName);
        using var buffer = new MemoryStream();
        await packaged.CopyToAsync(buffer);
        var bytes = buffer.ToArray();

        var container = Foundation.NSFileManager.Default.GetContainerUrl(FilterIdentity.AppGroupId);
        if (container is null)
        {
            return "App Group container is unavailable. The host must be signed with the App Groups entitlement before this write succeeds.";
        }

        var destination = container.Append(FilterIdentity.RulesFileName, isDirectory: false);
        var path = destination.Path;
        if (string.IsNullOrEmpty(path))
        {
            return "App Group URL has no filesystem path.";
        }

        await File.WriteAllBytesAsync(path, bytes);
        return $"Wrote {bytes.Length} bytes to {path}";
    }
}
