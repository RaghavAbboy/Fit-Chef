# FitChef Database Schema Explanation

This document explains the structure of the PostgreSQL database used by the FitChef application, managed via Supabase. It's intended to help beginners understand how user data, routines, and daily tasks are stored.

## Core Concepts

The application revolves around three main ideas:

1.  **Users:** Individuals who use the app. User authentication (login, signup) is handled by Supabase Auth, which stores core user details.
2.  **Routine Tasks:** These are templates defined by users for tasks they want to do regularly (e.g., "Drink 8 glasses of water", "Go for a run"). Users define the task description and how often it should repeat (daily, specific days of the week).
3.  **Daily Task Status:** For each routine task that's supposed to happen on a given day, the application creates a specific entry for that day to track whether the user completed it or not.

## Tables

The database uses several tables to store this information. The main ones are in the `public` schema:

### 1. `auth.users` (Managed by Supabase Auth)

*   **Purpose:** This table is automatically managed by Supabase Authentication. It stores the fundamental information about registered users, like their unique ID, email, sign-up time, etc.
*   **Key Column:**
    *   `id` (UUID): A unique identifier for each user. This ID is used in other tables to link data back to a specific user.
*   **Note:** We don't usually modify this table directly; Supabase handles it during login/signup.

### 2. `public.profiles`

*   **Purpose:** Stores additional public profile information associated with each user, extending the basic info in `auth.users`.
*   **Key Columns:**
    *   `id` (UUID): The primary key for this table. Crucially, this is **also** a foreign key that **matches the `id` from `auth.users`**. This creates a one-to-one link between a user's auth record and their profile.
    *   `username` (Text): A user-chosen username. Must be unique and at least 3 characters long.
    *   `full_name` (Text): The user's full name (optional).
    *   `updated_at` (Timestamp with Time Zone): Automatically records when the profile was last modified.
*   **Relationships:** Directly linked one-to-one with `auth.users` via the `id` column.
*   **Security:** Row Level Security (RLS) is **enabled**. Policies ensure users can only update/insert their *own* profile, but authenticated users can read others (as configured).

### 3. `public.routine_tasks`

*   **Purpose:** Stores the templates for recurring tasks created by users.
*   **Key Columns:**
    *   `id` (UUID): Unique identifier for each routine task template.
    *   `user_id` (UUID): Links to the `id` in `auth.users`, indicating which user owns this task definition.
    *   `description` (Text): The text describing the task (e.g., "Morning Jog").
    *   `repeat_daily` (Boolean): `true` if the task repeats every day.
    *   `repeat_monday`, `repeat_tuesday`, ... `repeat_sunday` (Boolean): `true` if the task repeats on that specific day (used only if `repeat_daily` is `false`).
    *   `is_active` (Boolean): A flag (`true`/`false`) to indicate if this routine should currently generate daily tasks. Defaults to `true`. Allows users to temporarily disable routines without deleting them.
    *   `created_at`, `updated_at` (Timestamp with Time Zone): Timestamps tracking creation and last modification. `updated_at` is handled automatically by a trigger.
*   **Relationships:** Linked many-to-one to `auth.users` (one user can have many routine tasks).
*   **Security:** Row Level Security (RLS) is **enabled**. Users can only access/modify their own routine task definitions.

### 4. `public.daily_task_status`

*   **Purpose:** Tracks the completion status of a specific routine task *for a specific user on a specific date*. This table gets populated daily based on active routines.
*   **Key Columns:**
    *   `id` (UUID): Unique identifier for this specific daily task instance.
    *   `user_id` (UUID): Links to the `id` in `auth.users`. Indicates who this status belongs to.
    *   `routine_task_id` (UUID): Links to the `id` in `routine_tasks`. Indicates which routine template this status entry corresponds to.
    *   `task_date` (Date): The specific date this status entry is for (e.g., '2024-05-21').
    *   `is_completed` (Boolean): Tracks whether the user marked this task as complete for `task_date`. Defaults to `false` when created.
    *   `completed_at` (Timestamp with Time Zone): Records the exact time the task was marked as complete (null if not completed).
*   **Relationships:**
    *   Linked many-to-one to `auth.users` (a user has status entries for many tasks/days).
    *   Linked many-to-one to `routine_tasks` (a routine task has status entries for many days/users).
*   **Security:** Row Level Security (RLS) is **enabled**. Users can only access/modify their own daily task statuses.

### 5. `public.macro_goals`

*   **Purpose:** Stores user-specific macronutrient targets, primarily their daily calorie goal. Designed for a one-to-one relationship with a user.
*   **Key Columns:**
    *   `id` (UUID): Unique identifier for this macro goal set.
    *   `user_id` (UUID): Links to `auth.users`. **Unique constraint** ensures a user has only one macro goal record.
    *   `daily_calorie_budget` (Integer): The user's target daily calorie intake (default 2000, constrained 500-10000).
    *   `created_at`, `updated_at` (Timestamp with Time Zone): Timestamps for record creation and last modification.
*   **Relationships:** Linked one-to-one to `auth.users`. Referenced by `health_goals`.
*   **Security:** Row Level Security (RLS) is **enabled**. Users can only manage their own macro goals.

### 6. `public.health_goals`

*   **Purpose:** Acts as a central linking table for a user's various specific health goal records (like macro goals). Currently links only to `macro_goals` but designed for potential future expansion (e.g., linking to fitness goals). Designed for a one-to-one relationship with a user.
*   **Key Columns:**
    *   `id` (UUID): Unique identifier for the user's overall health goal set.
    *   `user_id` (UUID): Links to `auth.users`. **Unique constraint** ensures a user has only one `health_goals` record.
    *   `macro_goals_id` (UUID): Links to the user's specific record in `public.macro_goals`. **Unique constraint** further enforces the 1-to-1 link.
    *   `created_at`, `updated_at` (Timestamp with Time Zone): Timestamps for record creation and last modification.
*   **Relationships:** Linked one-to-one to `auth.users` and `public.macro_goals`.
*   **Security:** Row Level Security (RLS) is **enabled**. Users can only manage their own health goals.

### 7. `public.calorie_activity`

*   **Purpose:** Records individual calorie-related events logged by the user, such as food intake or manual adjustments.
*   **Key Columns:**
    *   `id` (UUID): Unique identifier for each calorie log entry.
    *   `user_id` (UUID): Links to `auth.users`, indicating who logged this entry.
    *   `calories` (Integer): The number of calories associated with this entry (constrained 1-10000).
    *   `operation` (`calorie_operation` ENUM): Indicates how this entry affects the user's remaining budget.
        *   `'decrease'`: Reduces the remaining budget (used for food intake, manual subtractions).
        *   `'increase'`: Increases the remaining budget (used for manual additions, potential future exercise credits).
    *   `activity` (`calorie_activity_action` ENUM): Describes the type of activity logged.
        *   `'food_intake'`: Calories logged from eating food.
        *   `'manual_adjustment'`: Calories added or subtracted manually by the user.
    *   `description` (Text): Optional user-provided description (e.g., "Lunch - Salad", "Manual Fix").
    *   `activity_timestamp` (Timestamp with Time Zone): When the activity occurred (defaults to `now()`).
    *   `created_at` (Timestamp with Time Zone): Timestamp for record creation.
*   **Relationships:** Linked many-to-one to `auth.users`.
*   **Security:** Row Level Security (RLS) is **enabled**. Users can only manage their own calorie activities.

## Important Functions & Triggers

*   **`handle_new_user()` (Trigger Function):** This likely runs automatically whenever a new user is created in `auth.users`. Its job is probably to create a corresponding entry in the `public.profiles` table for that new user.
*   **`create_default_user_goals()` (Trigger Function on `auth.users` INSERT):** Automatically creates default entries in `public.macro_goals` (with the default `daily_calorie_budget`) and `public.health_goals` for every new user upon signup, ensuring they have initial calorie goals set up.
*   **`generate_daily_tasks_for_user(target_user_id UUID, target_date DATE)` (Database Function):** This function is called by the application (usually when the user visits their daily routine screen). It looks at the specified user's `routine_tasks` that are active and match the repetition schedule for the `target_date`. If an entry for that task doesn't already exist in `daily_task_status` for that user and date, this function creates it (with `is_completed` set to `false`).
*   **`moddatetime()` / `handle_updated_at` (Trigger Function):** This is a standard setup. A trigger named `handle_updated_at` is placed on the `routine_tasks` table. Before any row is updated, this trigger calls the `moddatetime()` function, which automatically sets the `updated_at` column to the current time.

## Relationships Summary

*   Everything centers around the `auth.users` table.
*   A user has one `profiles` entry.
*   A user can define many `routine_tasks`.
*   For each day a `routine_task` is active for a user, an entry is created in `daily_task_status` linking the user, the routine task, and the specific date.
*   A user has one `macro_goals` entry (via `health_goals`).
*   A user can log many `calorie_activity` entries.

This structure allows the app to efficiently manage user-defined routines and track their completion on a daily basis while ensuring users can only see and modify their own data.