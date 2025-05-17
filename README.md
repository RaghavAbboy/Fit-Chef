# Cursor Fitchef

A Flutter project for FitChef application.

## Architecture Documentation

Detailed documentation regarding the application's architecture, including backend schema design, can be found in the [`App Architecture and Design Documentation/`](./App%20Architecture%20and%20Design%20Documentation/) directory. See specifically:

*   [`backend_design_doc.md`](./App%20Architecture%20and%20Design%20Documentation/backend_design_doc.md): Explanation of the database schema.

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

8. **Cursor Rules**
   To your Project Rules, add:
   "Before you execute on any prompt, read `project_ai_instructions.md` for additional context"

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
| `git_push.sh`    | Stashes changes, pulls latest, restores changes, adds, commits, and pushes to git.      | `./git_push.sh "commit message" [branch_name]` |
| `git_pull.sh`    | Stashes changes, pulls latest from git, restores changes.                               | `./git_pull.sh [branch_name]`                  |
| `run_app.sh`     | Runs the Flutter app in iOS, Android, or Web mode based on the argument provided.       | `./run_app.sh ios`<br>`./run_app.sh android <android_device_id>`<br>`./run_app.sh web` |
| `run_and_log.sh` | Runs any command, logs its output to last_command_output.txt, and prints the output.    | `./run_and_log.sh ls -la`                      |
| `deploy.sh`      | Triggers a manual deployment to AWS Amplify for the main branch.                        | `./deploy.sh`                                  |

**Details:**
- `setup.sh`: Ensures your environment is ready for development (Flutter, CocoaPods, dependencies, clean build).
- `git_push.sh`: Automates pushing changes.
    - Fetches the latest from `origin`.
    - Switches your local working copy to the remote's default branch (e.g., `main` or `dev`).
    - Stashes local changes, pulls the latest for the default branch, and re-applies stashed changes.
    - Adds all current files and commits them with the provided `commit message`.
    - If `branch_name` (optional) is provided, it pushes the commits to that specified branch on `origin`.
    - If no `branch_name` is provided, it pushes to the remote's default branch.
    - Usage: `./git_push.sh "your commit message"` or `./git_push.sh "your commit message" your_target_branch`
- `git_pull.sh`: Safely pulls the latest changes.
    - Fetches the latest from `origin` (and prunes stale remote branches).
    - If `branch_name` (optional) is provided:
        - Switches your local working copy to `branch_name` (creating it locally if it only exists on `origin`).
        - Stashes local changes, pulls the latest for `branch_name` from `origin`, and re-applies stashed changes.
    - If no `branch_name` is provided:
        - Switches your local working copy to the remote's default branch (e.g., `main` or `dev`).
        - Stashes local changes, pulls the latest for the default branch from `origin`, and re-applies stashed changes.
    - Usage: `./git_pull.sh` or `./git_pull.sh your_target_branch`
- `run_app.sh`: Runs the Flutter app in the selected mode: iOS (opens Simulator), Android (requires device ID), or Web (Chrome browser).
- `run_and_log.sh`: Runs any command you provide, logs its output (stdout and stderr) to `last_command_output.txt` (overwriting previous output), and prints the output to the terminal. Useful for sharing command output with others or for debugging.

## Development Workflow & Branching Strategy

This project uses a branching model to manage development, testing, and production releases. The primary branches involved are:

-   **`dev`**: This is the main development branch. All new features, bug fixes, and ongoing development work should be based on and merged into this branch.
    -   Commit frequently to your feature branches and merge into `dev` once a feature is complete or a logical chunk of work is done.
    -   Use the `./git_push.sh "Your message" dev` command (or simply `./git_push.sh "Your message"` if `dev` is your remote's default) to push changes to this branch.

-   **`stage`**: Once features in the `dev` branch are considered stable and ready for more comprehensive testing (e.g., UAT or internal QA), they should be merged into the `stage` branch.
    -   The `stage` branch should represent a release candidate.
    -   Deploy this branch to a staging environment for testing.
    -   To push `dev` to `stage` (after ensuring your local `dev` is up-to-date and you are on it):
        1.  Ensure your local `dev` branch is current: `./git_pull.sh dev`
        2.  Switch to `stage` locally, creating it if it doesn't exist and ensuring it's up-to-date: `./git_pull.sh stage`
        3.  Merge `dev` into `stage`: `git merge dev` (resolve any conflicts)
        4.  Push the updated `stage` branch: `./git_push.sh "Merge dev into stage for testing" stage`

-   **`main`**: This branch represents the production-ready code. Only stable, tested code from the `stage` branch should be merged into `main`.
    -   Deployments to the production environment should be made from this branch.
    -   To promote `stage` to `main`:
        1.  Ensure your local `stage` branch is current: `./git_pull.sh stage`
        2.  Switch to `main` locally, creating it if it doesn't exist and ensuring it's up-to-date: `./git_pull.sh main`
        3.  Merge `stage` into `main`: `git merge stage` (resolve any conflicts)
        4.  Push the updated `main` branch: `./git_push.sh "Release to production from stage" main`
        5.  Optionally, tag the release: `git tag -a v1.x.x -m "Version 1.x.x release"` and `git push origin v1.x.x`

**General Guidelines:**

*   **Feature Branches:** For any new feature or significant bug fix, create a new branch off `dev` (e.g., `feature/new-login` or `fix/calorie-bug`). Once complete, merge this feature branch back into `dev`.
*   **Pull Regularly:** Before starting new work or pushing changes, always pull the latest from the respective branch to avoid conflicts (`./git_pull.sh branch_name`).
*   **Test Thoroughly:** Ensure changes are tested on `dev` and especially on `stage` before merging to `main`.

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
- User authentication (Google Sign-In on Web)
- **Calorie Hub:**
    - View daily calorie budget and remaining calories.
    - Track consumed calories for the day.
    - Log food intake (calories and optional description), which reduces the remaining daily budget.
    - Log exercise (calories and optional description), which increases the remaining daily budget.
    - Quickly add or subtract calories using +/- buttons for manual adjustments.
    - **Customize daily calorie budget** with an intuitive edit interface.
- My Daily Routine (Details TBD)

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
