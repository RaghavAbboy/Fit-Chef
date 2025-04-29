# Cursor Fitchef

A Flutter project for FitChef application.

## Development Setup

### Prerequisites
1. Install [Flutter](https://docs.flutter.dev/get-started/install)
2. Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835) (for iOS development)
3. Install [Android Studio](https://developer.android.com/studio) (for Android development)
4. Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) (for iOS dependencies):
   ```bash
   sudo gem install cocoapods
   ```
5. Install [Node.js and npm](https://nodejs.org/) (needed for the Supabase MCP Server)
6. Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html):
   ```bash
   # For macOS
   curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
   sudo installer -pkg AWSCLIV2.pkg -target /
   
   # Verify installation
   aws --version
   ```
7. **(Cursor Users Only)** Setup Supabase MCP Server for Supabase Tools:
   - Obtain a Supabase Access Token:
     1. Go to your [Supabase Account Tokens](https://app.supabase.com/account/tokens).
     2. Click "Generate New Token".
     3. Give it a descriptive name (e.g., "Cursor MCP Token").
     4. Click "Generate Token" and **copy the token immediately** (it won't be shown again).
   - In Cursor, go to `File > Preferences > Settings`, search for "MCP", and click "Edit settings.json" under "Model Context Protocol: Servers".
   - Add a new server configuration like this, replacing `YOUR_SUPABASE_ACCESS_TOKEN` with the token you just copied:
     ```json
     {
       "supabase": {
         "command": "npx -y @supabase/mcp-server-supabase@latest --access-token YOUR_SUPABASE_ACCESS_TOKEN",
         "enabled": true
       }
     }
     ```
   - Save the `settings.json` file.
   - You may need to restart the server process or Cursor if the Supabase tools don't appear immediately.

### AWS Amplify Setup
1. Configure AWS CLI with your credentials:
   ```bash
   aws configure
   ```
   You'll need to provide:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (use the region where your Amplify app is deployed)
   - Default output format (enter 'json')

   To get your AWS credentials:
   1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam)
   2. Click on "Users" in the left sidebar
   3. Click "Create user" or select your user
   4. Under "Security credentials", create an access key
   5. Save the Access Key ID and Secret Access Key

2. Ensure the user has required permissions:
   - Go to the IAM Console
   - Select your user
   - Click "Add permissions"
   - Search for and attach "AdministratorAccess-Amplify"

3. Verify Amplify CLI setup:
   ```bash
   # Test AWS CLI configuration
   aws amplify list-apps
   
   # This should show your Amplify apps, including Fit-Chef
   ```

### Getting Started

1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd cursor_fitchef
   ```

2. Run the setup script (see [Scripts](#project-scripts) section for details):
   ```bash
   ./setup.sh
   ```
   This will verify required tools, install dependencies, and prepare the project.

3. (Manual alternative) Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

4. (Manual alternative) Install iOS dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

5. Setup simulators/emulators:
   - For iOS: Open Xcode, go to Xcode > Open Developer Tool > Simulator
   - For Android: Open Android Studio > Tools > Device Manager > Create Device

### Running the App (iOS, Android, Web)

You can run the app on different platforms using the provided script:

- **iOS Simulator:**
  ```bash
  ./run_app.sh ios
  ```
  (Opens the iOS Simulator and runs the app)

- **Android Emulator:**
  ```bash
  ./run_app.sh android <android_device_id>
  ```
  (Start your Android emulator from Android Studio or with `flutter emulators`. Replace `<android_device_id>` with your device ID.)

- **Web (Chrome):**
  ```bash
  ./run_app.sh web
  ```
  (This will launch the app in Google Chrome on port 3000 by default. Make sure your Supabase and Google Cloud redirect URIs use port 3000.)

To see all available devices:
```bash
flutter devices
```

**Tip:** To log the output of any command you run (for sharing or debugging), use the `run_and_log.sh` script as described in the Project Scripts section below.

## Project Scripts

This project provides several scripts to automate common tasks. Make sure each script is executable:
```bash
chmod +x setup.sh git_push.sh git_pull.sh run_app.sh deploy.sh
```

| Script           | Purpose                                                                                 | Usage Example                                  |
| ---------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `setup.sh`       | Sets up the Flutter project: checks for tools, installs dependencies, cleans builds.     | `./setup.sh`                                   |
| `git_push.sh`    | Stashes changes, pulls latest, restores changes, adds, commits, and pushes to git.      | `./git_push.sh "your commit message"`          |
| `git_pull.sh`    | Stashes changes, pulls latest from git, restores changes.                               | `./git_pull.sh`                                |
| `run_app.sh`     | Runs the Flutter app in iOS, Android, or Web mode based on the argument provided.       | `./run_app.sh ios`<br>`./run_app.sh android <android_device_id>`<br>`./run_app.sh web` |
| `run_and_log.sh` | Runs any command, logs its output to last_command_output.txt, and prints the output.    | `./run_and_log.sh ls -la`                      |
| `deploy.sh`      | Triggers a manual deployment to AWS Amplify for the main branch.                        | `./deploy.sh`                                  |

**Details:**
- `setup.sh`: Ensures your environment is ready for development (Flutter, CocoaPods, dependencies, clean build).
- `git_push.sh`: Automates the process of safely pushing your changes to the current git branch. Requires a commit message.
- `git_pull.sh`: Safely pulls the latest changes from the current git branch, preserving your local changes.
- `run_app.sh`: Runs the Flutter app in the selected mode: iOS (opens Simulator), Android (requires device ID), or Web (Chrome browser).
- `run_and_log.sh`: Runs any command you provide, logs its output (stdout and stderr) to `last_command_output.txt` (overwriting previous output), and prints the output to the terminal. Useful for sharing command output with others or for debugging.

# Web mode uses port 3000 by default.

## Common Issues and Solutions

- If you encounter CocoaPods issues:
  ```bash
  cd ios
  pod deintegrate
  pod setup
  pod install
  ```

- If Flutter doctor shows issues:
  ```bash
  flutter doctor
  ```
  Follow the recommendations to resolve any issues.

## Additional Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter Documentation](https://docs.flutter.dev/)

## External Services

- [Supabase Dashboard](https://app.supabase.com/): Manage your database, authentication, and project settings.
- [Google Cloud Console](https://console.cloud.google.com/apis/credentials): Set up OAuth credentials for Google sign-in.

## Troubleshooting

If you encounter any issues:
1. Ensure all prerequisites are installed correctly
2. Run `flutter doctor -v` for detailed environment information
3. Check that all environment variables are set correctly
4. For iOS issues, try cleaning the build:
   ```bash
   cd ios
   xcodebuild clean
   cd ..
   flutter clean
   ```

## Features

- Animated falling fruits and vegetables on the landing page
- Sign in with Google is currently supported on the web version of the app

## Deployment

### AWS Amplify Deployment
The project is configured for manual deployments to AWS Amplify. To deploy:

0. Prerequisites:
   - Complete the [AWS Amplify Setup](#aws-amplify-setup) section above
   - Ensure you have the necessary AWS credentials and permissions

1. Make sure your changes are pushed to GitHub:
   ```bash
   ./git_push.sh "your commit message"
   ```

2. Deploy to AWS Amplify:
   ```bash
   ./deploy.sh
   ```

The deploy script will trigger a build on AWS Amplify for the main branch. You can monitor the build status in the AWS Amplify Console.

**Note:** Auto-build is disabled to give you control over when to deploy changes. Each deployment will build and deploy the latest commit from the specified branch.

**Troubleshooting Deployments:**
- If you get permissions errors, verify your AWS credentials with `aws configure list`
- If you get "command not found: aws", reinstall the AWS CLI
- If the deployment fails, check the build logs in the AWS Amplify Console
- Ensure your IAM user has the "AdministratorAccess-Amplify" policy attached
