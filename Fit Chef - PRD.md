# Product Requirements Document: FitChef

## 1. Introduction

FitChef is a cross-platform application designed to [**Inferred Goal:** likely assist users with fitness-related nutrition, meal planning, or healthy recipes]. It leverages Flutter for the frontend, enabling deployment across iOS, Android, and Web platforms. The backend is powered by Supabase, and the application is deployed via AWS Amplify.

## 2. Goals

*   Provide a user-friendly interface for [**Inferred Goal:** accessing recipes, planning meals, tracking nutrition, etc.].
*   Offer seamless user authentication.
*   Ensure a consistent experience across Web, iOS, and Android.
*   Establish a scalable backend infrastructure using Supabase.
*   Implement a reliable deployment pipeline using AWS Amplify.

## 3. Target Audience

*   [**Inferred:** Individuals interested in fitness, healthy eating, meal preparation, and tracking nutritional intake.]

## 4. Features

*   **Cross-Platform Availability:** Runs on iOS, Android, and Web (Chrome).
*   **User Authentication:**
    *   Google Sign-In (Currently supported on Web).
    *   Leverages Supabase for authentication services.
*   **Landing Page:** Features an animated display of falling fruits and vegetables.
*   **Calorie Hub:**
    *   Displays user's daily calorie budget.
    *   Calculates and displays calories consumed (reducing the budget) and remaining calories.
    *   Provides visual feedback (colors, messages) for calorie deficit/surplus.
    *   **Food Logging:** Allows users to log food intake (calories and optional description). Logged food uses an `operation: 'decrease'` in the `calorie_activity` table, signifying it reduces the available daily budget. The `activity` type is `'food_intake'`.
    *   **Quick Adjustments:** Provides "+" and "-" buttons for users to make manual calorie adjustments. These use an `operation: 'increase'` (adds to budget) or `'decrease'` (subtracts from budget) respectively, with an `activity` type of `'manual_adjustment'`.
*   **Backend Integration:** Utilizes Supabase for database and backend functionalities (schema defined in `App Architecture and Design Documentation/backend_design_doc.md`), including tables for `macro_goals` (daily budget) and `calorie_activity` (logged entries with `operation` and `activity` types).
*   **Deployment:** Manually deployed to AWS Amplify (details in `README.md`).
*   **My Daily Routine:** (Functionality TBD)
*   **[Inferred Core Features]:** Based on the name "FitChef" and the existence of a backend schema, the app likely includes core features related to:
    *   Recipe browsing/management
    *   Meal planning
    *   Nutritional information display
    *   (Potentially) Grocery list generation or user profiles.

## 5. Design & Architecture

*   **Frontend Framework:** Flutter
*   **Backend Platform:** Supabase (Database, Auth, potentially other services)
*   **Cloud Hosting/Deployment:** AWS Amplify
*   **Development Environment:** Requires Flutter SDK, Xcode (iOS), Android Studio (Android), Node.js (for Supabase tools), AWS CLI, CocoaPods (iOS).

## 6. Non-Goals (Based on Current Info)

*   Automated CI/CD deployment (currently manual via `deploy.sh`).
*   Authentication methods other than Google Sign-In (at least as explicitly stated).

---
**Note:** Sections marked as **[Inferred Goal/Feature]** are logical assumptions based on the project name and technical setup described in the README. The exact user-facing purpose and detailed features would require more specific project documentation (like user stories or detailed feature specs) beyond the setup and architecture information provided. 