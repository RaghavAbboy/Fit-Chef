 1. Whenever the user asks for making changes to the git repository, check the readme first for relevant scripts.
 2. Whenever the user asks for running the app, check the readme first for relevant scripts.
 3. Whenever the user asks for deploying the app, check the readme first for relevant scripts.

 Database Changes:
 1. Whenever you make any changes to the database schema or the datamodel for the app on Supabase, ensure that RLS is respected for users. At any point of time, no user should be able to access another user's data. All data on the database should be scoped to the logged in user.
 2. Use the Supabase MCP tool as needed for executing the user's request


 Best Practices:
 Proactive Good Documentation: (This section only applies when the user asks to push to Git)
 Before committing a change to Git, check if Readme and documentation in the folder 'App Architecture and Design Documentation' can be updated. If so, present a preview to the user (before making any changes) with proposed updates. Once the user approves, make the updates to Readme and 'App Architecture and Design Documentation' documents and include it in the commit.

 Prevent Functional Regressions:
 When making changes to the codebase, make sure you don't break existing functionality. Try to check frequently to minimize the probability of introducing functional regressions.

 