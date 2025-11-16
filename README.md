# LeetCode Progress Widget for macOS

A native macOS widget that displays your LeetCode submission progress on your desktop. Built with SwiftUI and WidgetKit for macOS Tahoe (16.0+).

## Features

- 📊 **Total Problems Solved**: Shows your current LeetCode submission count
- 📅 **Full Year Calendar**: Visual calendar showing submission activity over the last 12 months (organized in a 3×4 month grid)
- 📱 **Desktop Widget**: Compact 7×7 grid (49 days) for quick desktop access
- 🔄 **Auto-Sync**: Configurable sync frequency (Live, Hourly, Daily)
- 💾 **Smart Caching**: Data cached locally with automatic refresh
- 🌐 **Offline Support**: Works with cached data when offline
- 🎨 **Modern Design**: Native macOS Tahoe UI with rounded fonts and clean styling
- 🚀 **Standalone App**: Use as both a widget and a full-featured macOS app with first-time setup wizard

## Screenshots

The app displays:
- **Title**: "LeetCode Progress"
- **Subtitle**: "Solved X problems"
- **Full Year Calendar**: 12 months organized in a 3×4 grid, each month showing submission activity
- **Grid Squares**: Green = days with submissions, Grey = days without submissions

The widget shows:
- **Compact View**: 7×7 grid (49 days) with the same visual style
- **Title**: "LeetCode Progress"
- **Subtitle**: "Solved X problems"

## Requirements

- **macOS**: 16.0 (Tahoe) or later
- **Xcode**: 16.0 or later
- **Swift**: 5.0 or later

## Installation

### Option 1: Build from Source

1. **Clone or download this repository**
2. **Open** `LeetCodeWidget.xcodeproj` in Xcode
3. **Configure App Groups** (see Setup section below)
4. **Build and run** (Cmd+R)

### Option 2: Use Pre-built DMG

1. **Download** `LeetCodeWidget.dmg`
2. **Mount** the DMG and drag the app to Applications
3. **Right-click** the app → **Open** (to bypass security warning)
4. **Launch** the app to register the widget

## Setup

### 1. Configure App Groups

App Groups allow the widget and main app to share data. Configure for **both targets**:

1. Select **LeetCodeWidget macOS** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** → Add **App Groups**
4. Add identifier: `group.com.leetcode.widget`
5. Repeat for **LeetCodeWidget Extension** target

**Important**: Both targets must use the same App Group identifier.

### 2. Configure Code Signing

For each target (macOS app and Widget Extension):

1. Go to **Signing & Capabilities**
2. Select your **Team** (or add your Apple ID)
3. Xcode will automatically generate provisioning profiles

**Note**: A free Apple Developer account works for development.

### 3. Set Your LeetCode Username

**Method 1: Via Widget Settings (Recommended)**
- Right-click the widget on your desktop
- Select **Edit Widget**
- Enter your LeetCode username
- Choose sync frequency
- Click **Done**

**Method 2: Via Main App**
- Launch the main app
- The app will prompt you to configure your username
- Enter your LeetCode username

## Usage

### Adding the Widget

1. **Launch the app** first (this registers the widget with macOS)
2. **Right-click** on your desktop
3. Select **Edit Widgets**
4. Search for **"LeetCode"** or **"LeetCode Widget"**
5. Click the **+** button to add it to your desktop

**Note**: If the widget doesn't appear in the gallery, see Troubleshooting below.

### Configuring the Widget

Right-click the widget → **Edit Widget** to configure:
- **LeetCode Username**: Your LeetCode profile username
- **Sync Frequency**:
  - **Live**: Updates every minute
  - **Every Hour**: Updates hourly
  - **Every Day**: Updates daily (default)

### Using the Main App

The main app provides a full-featured experience:
- **First-Time Setup**: Prompts for LeetCode username on first launch
- **Full Year View**: See all 12 months of submission activity in a scrollable grid
- **Change Username**: Update your LeetCode username anytime from the app
- **Manual Refresh**: Click **Refresh Data** to manually update
- **Detailed Calendar**: Each month shows a complete calendar grid with day-of-week alignment

## Project Structure

```
LeetCodeWidget/
├── macOS/                      # macOS app target
│   ├── LeetCodeWidgetApp.swift
│   ├── ContentView.swift
│   └── Info.plist
├── Widget/                     # Widget Extension
│   ├── LeetCodeWidget.swift
│   ├── LeetCodeWidgetBundle.swift
│   ├── LeetCodeWidgetConfiguration.swift
│   └── Info.plist
└── Shared/                      # Shared code
    ├── Models/
    │   └── LeetCodeData.swift
    ├── Networking/
    │   └── LeetCodeAPI.swift
    └── Cache/
        ├── DataCache.swift
        └── WidgetConfiguration.swift
```

## How It Works

1. **Data Fetching**: Fetches data from LeetCode's GraphQL API
2. **Caching**: Stores data in App Group shared container
3. **Refresh Logic**: Updates based on configured sync frequency
4. **Display**: 
   - **App**: Shows total solved and full year (12 months) submission calendar
   - **Widget**: Shows total solved and compact 49-day submission calendar

## Building a DMG

To create a distributable DMG file:

```bash
./build_and_create_dmg.sh
```

This will:
- Build the app and widget extension
- Create a DMG file ready for distribution
- Output: `LeetCodeWidget.dmg`

**Note**: The script builds without code signing by default. To sign the app:

```bash
./build_and_create_dmg.sh --sign "Your Signing Identity"
```

## Troubleshooting

### Widget Not Appearing in Gallery

**For Unsigned Apps:**
- macOS requires code signing for widgets to appear in the gallery
- **Solution 1**: Sign the app (see Code Signing section above)
- **Solution 2**: Run the widget extension directly from Xcode:
  1. Select **LeetCodeWidget Extension** scheme
  2. Press Cmd+R
  3. Widget will appear on desktop

**For Signed Apps:**
1. Make sure the app is in `/Applications`
2. Launch the app at least once
3. Wait 10 seconds for widget registration
4. Right-click desktop → Edit Widgets
5. Search for "LeetCode"

### Widget Not Showing Data

- Verify App Groups are configured for both targets
- Check that App Group identifier matches: `group.com.leetcode.widget`
- Ensure your LeetCode username is configured
- Try opening the main app and clicking "Refresh Data"

### Build Errors

- Ensure Xcode 16.0+ is installed
- Clean build folder: **Product → Clean Build Folder** (Shift+Cmd+K)
- Verify all targets have valid signing certificates
- Check that macOS deployment target is 16.0

### Network Issues

- Widget uses cached data if network fails
- Open main app and click "Refresh Data" to manually update
- Verify your LeetCode username is correct
- Check your internet connection

## Development

### Running from Xcode

1. Select **LeetCodeWidget macOS** scheme for the main app
2. Select **LeetCodeWidget Extension** scheme for the widget
3. Press Cmd+R to build and run

### Code Signing for Distribution

To distribute the app:

1. **Sign the app** with your Developer ID certificate
2. **Notarize** the app (required for Gatekeeper)
3. **Staple** the notarization ticket

See `build_and_create_dmg.sh` for automated build and signing options.

## API Details

The widget uses LeetCode's public GraphQL API:
- **Endpoint**: `https://leetcode.com/graphql`
- **Query**: Fetches `submissionCalendar` and `submitStats`
- **Rate Limiting**: No authentication required, but be respectful

## Author

**Suraj Van Verma**

## License

This project is provided as-is for educational and personal use.

## Contributing

Feel free to submit issues or pull requests. This is a minimal implementation focused on core functionality.
