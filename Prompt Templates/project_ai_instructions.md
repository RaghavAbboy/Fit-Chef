 1. Whenever the user asks for making changes to the git repository, check the readme first for relevant scripts.
 2. Whenever the user asks for running the app, check the readme first for relevant scripts.
 3. Whenever the user asks for deploying the app, check the readme first for relevant scripts.

 Database Changes:
 1. Whenever you make any changes to the database schema or the datamodel for the app on Supabase, ensure that RLS is respected for users. At any point of time, no user should be able to access another user's data. All data on the database should be scoped to the logged in user.
 