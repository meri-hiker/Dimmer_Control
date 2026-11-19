# HalfLight

A native macOS menu-bar app that darkens one side of a split-screen workspace. Requires macOS 13 Ventura or later. Built with SwiftUI and AppKit, with no dependencies.

## Install a ready-built app — no Xcode or Terminal

The project includes a GitHub Actions build that produces an Intel + Apple Silicon app and a drag-to-Applications disk image. A repository and a successful macOS workflow run are required before these downloads exist; the source ZIP itself is not an installable app.

Once the project has been uploaded to a GitHub repository:

1. Open the repository's **Actions** tab, select **macOS build**, and open a successful run. A push builds automatically, or use **Run workflow** to start a build.
2. Download **HalfLight-macOS** from **Artifacts** at the bottom of the run (GitHub sign-in is required).
3. Unzip the download and double-click **HalfLight.dmg**.
4. Drag **HalfLight.app** onto the **Applications** shortcut, eject the disk image, and open HalfLight from Applications.

No developer tools are needed on your Mac to install or run that build. It is locally signed, not Apple-notarized. If macOS blocks the first launch, use **System Settings → Privacy & Security → Open Anyway** after attempting to open it, and confirm the app name is HalfLight.

## Build and launch with Xcode — no Terminal needed

1. Install **Xcode 15 or later** from the Mac App Store. Open it once to finish installing its components.
2. Download and unzip this project, then double-click **HalfLight.xcodeproj**. Keep the whole project folder together.
3. In Xcode's toolbar, select the **HalfLight App** scheme and **My Mac** as the destination.
4. Click the **▶ Run** button. Xcode builds the application and launches it; look for the half-circle icon in your Mac's menu bar.

The project uses local ad-hoc signing, so a paid Apple Developer account or signing team is not needed to build for your own Mac. The shared core library is included locally; no external package download is needed.

### Keep the app in Applications

1. Choose **Product → Build** in Xcode.
2. In the project navigator, expand **Products**, right-click **HalfLight.app**, and choose **Show in Finder**.
3. Quit HalfLight if it is running, then copy **HalfLight.app** into your **Applications** folder in Finder.
4. Double-click the app in Applications whenever you want to use it. Xcode does not need to stay open.

To run the geometry tests without Terminal, choose **Product → Test** with the **HalfLight App** scheme selected.

This produces a local Mac app, not a Developer ID signed or notarized public release. A Mac running macOS 13 or later is required; Xcode itself may require a newer macOS version depending on the version you install.

## Optional command-line build

Install Xcode Command Line Tools (`xcode-select --install`) if needed. From this folder, run:

```sh
bash scripts/build-app.sh
open dist/HalfLight.app
```

The script creates a locally ad-hoc-signed app, `dist/HalfLight-macOS.zip`, and `dist/HalfLight.dmg`. Drag the app to Applications to keep it. By default it targets the build Mac's current architecture; pass `--universal` to build for both Intel and Apple Silicon, as the hosted workflow does. It is not a Developer ID signed or notarized public release.

Use **HalfLight.xcodeproj** for the graphical build workflow above. `Package.swift` remains available for Swift Package Manager development.

## Use

1. Arrange two apps side by side, using macOS Split View or desktop window tiling.
2. Click the half-circle icon in the menu bar.
3. Choose Left or Right, then switch on **Dim split screen**.
4. Adjust **Darkness** (10–85%) and **Split position** (20/80 through 80/20) to match your layout. Choose a display when multiple monitors are connected.
5. Pause dimming when leaving your split-screen workspace, or quit from the popover.

Global shortcuts:

| Action | Shortcut |
| --- | --- |
| Toggle dimming | Control–Option–Command–D |
| Swap dimmed side | Control–Option–Command–S |

If another app has registered either shortcut, HalfLight disables both shortcuts and shows that they are unavailable. The menu-bar controls remain usable.

## Behaviour and scope

- The black overlay passes all mouse events through, so both apps remain interactive. It does not change hardware brightness.
- It stays above ordinary application windows and is configured to accompany full-screen spaces, including native Split View. The menu bar stays accessible.
- Activation is manual. HalfLight does **not** detect native Split View or automatically stop when you change Spaces. While enabled, its shade follows Spaces on the selected display. Turn it off when leaving Split View.
- Left/right selection, darkness, divider, and display choice are saved. Dimming always starts paused after launch.
- Sleep, an inactive login session, or disconnection of the selected monitor pauses dimming. Re-enable it when ready.
- No Accessibility, Screen Recording, administrator access, or network access is required. Full-screen and multi-monitor behaviour still needs validation on real macOS hardware.

## Validation

On macOS with Xcode Command Line Tools:

```sh
swift test
bash scripts/build-app.sh
```

The tests cover equal and uneven splits, negative display coordinates, odd screen widths, and invalid preferences. The GitHub Actions workflow runs the package tests, builds and tests the Xcode project, and builds the app bundle on macOS when this folder is used as a repository.

Manual macOS checks:

- Enable each side in desktop tiling and in a native full-screen Split View Space; verify the intended pane is dimmed and clicks/scrolling still reach both apps.
- Move the Split View divider and match it with Split position; check 20/80, 50/50, and 80/20 layouts.
- Open the popover while dimming; verify the menu bar, Pause, Quit, and both global shortcuts work.
- Try an external display, including one positioned left of the primary display. Unplug the selected display; dimming should pause.
- Change Spaces, sleep/wake, log out/in, and relaunch. Verify the documented manual activation and pause behaviour.

This project was authored in a Linux workspace. The macOS application and XCTest suite have not been compiled or run there; the Mac build and the checks above are required before treating it as a tested release.
