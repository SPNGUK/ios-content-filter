# iOS content filter

.NET MAUI host for iPhone and iPad, plus two native Swift Network Extension app extensions. Milestone 1 is the skeleton: it compiles, embeds the extensions, and shares an App Group. It does not install a working filter and it does not sign the app.

The identifiers below are placeholders. They are valid reverse-DNS strings, and they are the values to register until you change them.

| Role | Value |
| --- | --- |
| Host bundle ID | `uk.spng.ioscontentfilter` |
| Filter data extension | `uk.spng.ioscontentfilter.FilterData` |
| Filter control extension | `uk.spng.ioscontentfilter.FilterControl` |
| App Group | `group.uk.spng.ioscontentfilter` |
| Keychain access group suffix | `group.uk.spng.ioscontentfilter` |
| Team ID | `YOUR_TEAM_ID` |

The signed keychain group is `TEAMID.group.uk.spng.ioscontentfilter`. Entitlements write that as `$(AppIdentifierPrefix)group.uk.spng.ioscontentfilter`, and Xcode fills in the Team ID at sign time.

## What changed from the original plan

Checked against Apple’s docs on 15 October 2026.

The host and the two `NEFilter*` extensions are still the right shape for **custom logic on each flow**. That part of the plan is current. The authorisation plan is not.

`NEFilterDataProvider` and `NEFilterControlProvider` are the Content Filter API. On iOS the system-wide content filter is supported on **supervised** devices. [TN3134](https://developer.apple.com/documentation/technotes/tn3134-network-extension-provider-deployment) also allows it for apps that use the Screen Time APIs, but only on a **child** device:

1. Add the Family Controls capability.
2. The iCloud account on the device is an under-18 child in a Family Sharing group.
3. Call `AuthorizationCenter.requestAuthorization(for: .child)`.
4. A parent or guardian approves.

`requestAuthorization(for: .individual)` is real, and it is how a person authorises Family Controls on their own device (iOS 16 and later). Apple’s Screen Time team told Developer Technical Support that this individual grant does **not** enable a Network Extension content filter. The individual grant covers Managed Settings and Device Activity. See [TN3134](https://developer.apple.com/documentation/technotes/tn3134-network-extension-provider-deployment) and the clarification on [Apple Developer Forums thread 736363](https://developer.apple.com/forums/thread/736363).

Distribution signing (Ad Hoc, TestFlight, App Store) enforces the supervised-device rule. A **development-signed** build includes `get-task-allow`, and that signature can save a filter configuration on an unsupervised device for debugging. Apple DTS said in May 2026 that this debugging affordance is still policy ([thread 827318](https://developer.apple.com/forums/thread/827318)); a report of `NEConfigurationErrorDomain` code 10 on iOS 26.4.2 was not accepted as a policy change. TestFlight and Ad Hoc builds do not have `get-task-allow`.

Other current options, and why this repo did not switch to them:

- **URL Filter (iOS 26 / iPadOS 26).** `NEURLFilterManager` and an `NEURLFilterControlProvider` extension run on unmanaged devices. The app does not sit on the filtering path and never sees the URL. Verdicts come from a Bloom filter plus Private Information Retrieval over Apple’s Oblivious HTTP relay. Distribution builds need Apple to approve that relay. This cannot run custom per-flow code. [WWDC25 session 234](https://developer.apple.com/videos/play/wwdc2025/234/), [TN3134](https://developer.apple.com/documentation/technotes/tn3134-network-extension-provider-deployment).
- **Managed Settings web content**, after individual Family Controls authorisation. Works on the owner’s own iPad. It applies Apple’s automatic filter or a domain allow/deny list. It is not a per-URL callback.
- **iOS 27 / iPadOS 27 declarative web content filter plug-in.** Supervision is no longer required, but the device still has to be enrolled (User Enrollment, Device Enrollment, or Automated Device Enrollment) and the filter is delivered as a device-management payload. [Apple Platform Deployment](https://support.apple.com/guide/deployment/web-content-filter-plugin-declarative-depcbacfcb0e/web).

Before milestone 2, pick one:

1. Supervise the iPad and keep `NEFilterDataProvider` for custom per-flow logic.
2. Use an under-18 child Apple ID, parent approval, and `.child` authorisation, and keep `NEFilterDataProvider`.
3. Move to the iOS 26 URL Filter if unmanaged-device distribution matters more than custom on-device logic.
4. Use Managed Settings domain lists if individual Family Controls on this iPad is the requirement, and custom per-flow logic is not.

Content filters do not run in the Simulator. Exercise them on a physical iPad.

The filter data provider runs in a small extension process with a tight memory limit. That is why the extensions are Swift, not .NET.

## Layout

```
src/IosContentFilter/                 MAUI host (net10.0-ios)
extensions/FilterExtensions/          Xcode project
  FilterData/                         NEFilterDataProvider appex
  FilterControl/                      NEFilterControlProvider appex
  Shared/                             App Group rules, keychain query, decision hook
shared/identity.props                 Canonical bundle IDs
shared/rules.sample.json              Document the host writes into the App Group
scripts/build-extensions.sh          Unsigned xcodebuild, then stage the appexes
scripts/check-identity.py             Fails if the IDs drift
.github/workflows/ios-compile.yml     macos-latest compile, no signing secrets
```

`FlowEvaluator.decide(_:)` in `extensions/FilterExtensions/Shared/FlowEvaluator.swift` is the hook. It logs a host-only description and returns `.allow`. Returning `.drop` blocks the flow. `FilterDataProvider.startFilter` installs an empty rule list with default action `.filterData`, so every new flow reaches that hook. Narrow the rules before this sees real traffic.

The host writes `rules.json` into the App Group. Both extensions read it through `RuleStore`. The host does not call `NEFilterManager.SaveToPreferences` in this milestone. `FilterConfigurationDraft` only builds the configuration object so the .NET binding is part of the compile.

`CODE_SIGN_ENTITLEMENTS` is left unset on the Xcode targets so `xcodebuild` can compile with `CODE_SIGNING_ALLOWED=NO`. The entitlement plists are still in the tree. The MAUI project points `AdditionalAppExtensions` at them, and a later signed build must also set:

- FilterData: `CODE_SIGN_ENTITLEMENTS = FilterData/FilterData.entitlements`
- FilterControl: `CODE_SIGN_ENTITLEMENTS = FilterControl/FilterControl.entitlements`

Set `CODE_SIGNING_ALLOWED = YES`, `DEVELOPMENT_TEAM`, and a signing identity at the same time.

## Changing bundle identifiers

1. Edit `shared/identity.props`.
2. Put the same strings in:
   - `src/IosContentFilter/FilterIdentity.cs`
   - `extensions/FilterExtensions/Shared/FilterConstants.swift`
   - `PRODUCT_BUNDLE_IDENTIFIER` in `extensions/FilterExtensions/FilterExtensions.xcodeproj/project.pbxproj`
   - the three `*.entitlements` plists (App Group, keychain suffix, and `content-filter-provider`)
3. The host `ApplicationId` is `$(FilterHostBundleId)` from the props file. Leave that reference in place.
4. Run `python3 scripts/check-identity.py`.

The host entitlement also contains `com.apple.developer.family-controls`. The extensions do not. They are Network Extensions, not Screen Time extensions.

## Build

Local and CI both need a Mac with Xcode and the .NET 10 SDK. `global.json` selects the newest installed .NET 10 feature band.

```bash
python3 scripts/check-identity.py
dotnet workload install maui-ios
bash scripts/build-extensions.sh
dotnet build src/IosContentFilter/IosContentFilter.csproj \
  -c Release \
  -f net10.0-ios \
  -p:RuntimeIdentifier=ios-arm64 \
  -p:EnableCodeSigning=false \
  -p:CodesignRequireProvisioningProfile=false \
  -p:ArchiveOnBuild=false \
  -p:SkipFilterExtensionBuild=true
```

`scripts/build-extensions.sh` runs `xcodebuild` for the `FilterExtensions` scheme (`generic/platform=iOS`, Release, `CODE_SIGNING_ALLOWED=NO`, identity `-`) and copies:

- `artifacts/appex/FilterData/Release-iphoneos/FilterData.appex`
- `artifacts/appex/FilterControl/Release-iphoneos/FilterControl.appex`

Those paths are what `AdditionalAppExtensions` embeds. `artifacts/` is gitignored. A plain `dotnet build` on macOS runs the script itself unless `-p:SkipFilterExtensionBuild=true` is set.

The script checks that the built Info.plists still declare `com.apple.networkextension.filter-data` and `com.apple.networkextension.filter-control`.

This compile does not produce an installable, signed `.ipa`.

## Continuous integration

`.github/workflows/ios-compile.yml` runs on `macos-latest`. It checks the identifiers, installs the `maui-ios` workload, builds the Swift extensions, then builds the MAUI app for `ios-arm64` with code signing off. The job fails if either compile fails. It uses no Apple secrets.

## What Siu provides before a signed install

Create these in the Apple Developer account (paid membership is already in place), then add the GitHub Actions secrets under the repository’s Settings → Secrets and variables → Actions. Use the exact names. Values are not committed.

Portal setup:

1. Note the 10-character Team ID.
2. Register an explicit App ID for each bundle ID: the host, `FilterData`, and `FilterControl`.
3. On each App ID enable **Network Extensions** and tick **Content Filter**. If Content Filter is missing from the capability list, ask Apple Developer Support to enable it for the account. There is no separate public form to assume.
4. Register the App Group `group.uk.spng.ioscontentfilter` and enable App Groups on all three App IDs.
5. Enable Keychain Sharing on all three App IDs and add `group.uk.spng.ioscontentfilter`.
6. Enable Family Controls on the **host** App ID. Development uses the normal capability. Distribution (TestFlight, Ad Hoc, App Store) needs the Account Holder to request the Family Controls distribution entitlement: [Request Family Controls](https://developer.apple.com/contact/request/family-controls-distribution). The host entitlement is already in `Entitlements.plist`, so a signed upload will be rejected until that request is approved, or until the entitlement is removed.
7. Create an Apple Distribution certificate and export it from Keychain Access as a `.p12` that includes the private key. Remember the export password.
8. Create a provisioning profile for each of the three App IDs.
   - TestFlight uses **App Store** profiles.
   - A direct install onto one iPad uses **Ad Hoc** profiles that include that iPad’s UDID. Register the UDID under Devices first. The UDID is not a GitHub secret; it has to be inside the profiles.
9. In App Store Connect, create an API key (Admin or App Manager) and download `AuthKey_<KeyID>.p8` once. Record the Key ID and the Issuer ID.

GitHub secrets:

| Secret | Contents |
| --- | --- |
| `APPLE_TEAM_ID` | 10-character Team ID |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | `base64 -i Distribution.p12` of the exported Apple Distribution certificate and private key |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password set when exporting the `.p12` |
| `IOS_PROFILE_HOST_BASE64` | `base64` of the `.mobileprovision` for `uk.spng.ioscontentfilter` |
| `IOS_PROFILE_FILTER_DATA_BASE64` | `base64` of the `.mobileprovision` for `uk.spng.ioscontentfilter.FilterData` |
| `IOS_PROFILE_FILTER_CONTROL_BASE64` | `base64` of the `.mobileprovision` for `uk.spng.ioscontentfilter.FilterControl` |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | `base64` of `AuthKey_<KeyID>.p8` |

Replace the bundle IDs in that table if `shared/identity.props` changes. This milestone’s workflow does not read the secrets. A later signing workflow will.

After the Team ID exists, replace `YOUR_TEAM_ID` in `FilterIdentity.cs` and `FilterConstants.swift` before any keychain call. `scripts/check-identity.py` requires the placeholder until those two files and `identity.props` change together.

## Next actions

1. Choose the deployment path in [What changed from the original plan](#what-changed-from-the-original-plan). The current extensions match paths 1 and 2 only.
2. Confirm or replace the bundle IDs, then create the three App IDs, the App Group, and the capabilities above.
3. Request Family Controls distribution approval before the first signed upload.
4. Export the distribution certificate and the three profiles, create the App Store Connect API key, and store them as the secrets in the table.
5. For an Ad Hoc install, register the iPad UDID and rebuild the three profiles so they include it.
6. Put the Team ID into the signing settings and into the keychain placeholder, set `CODE_SIGN_ENTITLEMENTS` on both extension targets, and only then try `NEFilterManager.SaveToPreferences` on a physical iPad.

## Out of scope

Real signing, TestFlight upload, UDID registration, custom filter decisions beyond the allow-all hook, and the Screen Time permission flow. The Screen Time button on the main page explains the gap and does not call Family Controls.
