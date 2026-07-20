# English Growth Tracker

The tracker is a static HTML application backed by Supabase Auth and one private
`tracker_state` JSONB row per user. It can be hosted on Vercel, GitHub Pages, or
any normal static web server. Display names live in Supabase Auth metadata and
profile images live in the `avatars` Storage bucket; neither is added to tracker JSON.

## Supabase setup

1. Create a project at [Supabase](https://supabase.com/dashboard).
2. Open **SQL Editor**, paste the complete contents of `supabase-setup.sql`, and run it.
   This creates the private tracker table, the public-read `avatars` bucket, its
   2 MB/MIME restrictions, and owner-folder write policies.
3. In **Project Settings → API**, copy the project URL and the publishable key.
4. Copy `supabase-config.example.js` to `supabase-config.js` if the local file does not already exist.
5. Replace the two placeholders in `supabase-config.js`:

   ```js
   window.SUPABASE_CONFIG = {
     url: "https://YOUR_PROJECT.supabase.co",
     publishableKey: "YOUR_PUBLISHABLE_KEY"
   };
   ```

The project URL and publishable key are intentionally public browser values.
Security comes from the Row Level Security policies in `supabase-setup.sql`.
Never use a secret key, `service_role` key, database password, or direct Postgres
connection string in frontend files.

## Authentication setup

1. In **Authentication → Providers**, keep Email enabled.
2. Decide whether new users must confirm their email. The tracker supports both modes.
3. In **Authentication → URL Configuration**, set the production Site URL.
4. Add every local and deployed tracker URL to **Redirect URLs**, including the full HTML path. Examples:

   - `http://localhost:8000/index.html`
   - `https://YOUR_PROJECT.vercel.app/`
   - `https://YOUR_USERNAME.github.io/YOUR_REPOSITORY/`

These redirect URLs are used for email confirmation and password recovery.

## Test locally

Serve the folder through a local static server rather than opening the file directly:

```text
python -m http.server 8000
```

Then open:

```text
http://localhost:8000/
```

Create two test accounts to verify that each account receives its own state.
Test study progress, set notes, vocabulary edits, Grammar rule management, flashcard grading, refresh,
sign-out/sign-in, the one-time browser-data migration, offline retry, and both
Vocabulary export formats. Also test signup names in English and Arabic, the
mandatory name prompt for an older account, avatar upload/replacement/removal,
and a rejected wrong-type or over-2-MB image.

## Deploy to Vercel

1. Push the folder to a Git repository. Include only the project URL and public
   publishable key in any deployed `supabase-config.js`.
2. For deployment, create `supabase-config.js` during the build from project-level
   public environment values, or commit a deployment-specific copy containing only
   the public project URL and publishable key.
3. Import the repository into Vercel.
4. Choose **Other** as the framework preset, leave the build command empty, and use
   the repository root as the output directory.
5. Deploy, add the final tracker URL to Supabase Auth Redirect URLs, and test sign-in.

## Deploy to GitHub Pages

1. Because GitHub Pages has no build-time secrets, commit a deployment copy of
   `supabase-config.js` containing only the public URL and publishable key, or publish
   it from a dedicated deployment workflow.
2. In repository **Settings → Pages**, deploy from the desired branch and root folder.
3. Open the deployed `index.html` Pages URL.
4. Add that exact URL to Supabase Auth Redirect URLs and test email confirmation,
   password recovery, sign-in, cloud reload, and sign-out.

## Data and migration behavior

- Supabase is the source of truth for tracker state version 8.
- Supabase Auth may persist its login session in browser storage.
- Tracker progress, notes, vocabulary, grammar rules, and flashcard statuses are not written to
  browser storage.
- `display_name` and `avatar_url` are stored in Supabase Auth user metadata.
- Avatar files are stored as `USER_ID/avatar.webp` in Supabase Storage. The bucket
  is publicly readable for image delivery, while insert/update/delete access is
  limited by RLS to the authenticated user's own folder.
- On first sign-in, known version 1–5 browser keys are offered for explicit migration.
- Old application keys are removed only after the selected cloud state is written and
  read back successfully.
- Automatic saves use a short debounce and an `updated_at` comparison. If another
  device has written a newer copy, the tracker asks whether to reload it or explicitly
  keep this device's changes.

The frontend uses the pinned Supabase JavaScript v2 browser client from jsDelivr.
