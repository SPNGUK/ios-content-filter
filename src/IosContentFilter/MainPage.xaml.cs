namespace IosContentFilter;

public partial class MainPage : ContentPage
{
    public MainPage()
    {
        InitializeComponent();
    }

    private async void OnWriteRulesClicked(object? sender, EventArgs e)
    {
        try
        {
            StatusLabel.Text = "Writing sample rules…";
            StatusLabel.Text = await AppGroupRuleStore.WriteSampleAsync();
        }
        catch (Exception ex)
        {
            StatusLabel.Text = ex.Message;
        }
    }

    private void OnPrepareConfigurationClicked(object? sender, EventArgs e)
    {
        StatusLabel.Text = FilterConfigurationDraft.Describe();
    }

    private void OnScreenTimeClicked(object? sender, EventArgs e)
    {
        StatusLabel.Text =
            "Screen Time authorisation is not implemented in milestone 1. " +
            "AuthorizationCenter.requestAuthorization(for: .individual) lets the device owner approve Family Controls on their own iPad. " +
            "That approval covers Managed Settings and Device Activity. It does not let NEFilterManager save a content filter on a distribution-signed build. " +
            "The Screen Time path that can enable a content filter is requestAuthorization(for: .child), on an under-18 child in an iCloud family, approved by a parent or guardian. " +
            "Family Controls distribution approval is still required before TestFlight or the App Store, because the host entitlement is present.";
    }
}
