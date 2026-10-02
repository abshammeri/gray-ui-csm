---
name: deploy-preview
description: Clone a GitHub repo (no fork), install it, smoke-test it in a headless browser, deploy it to Cloudflare Workers, and return a public preview URL plus any login credentials. Use whenever the user shares a GitHub repo (owner/repo or URL) and wants it run, tested, previewed, hosted, or "put on Cloudflare" so they can open it on their phone, even if they never say "deploy".
---

# deploy-preview

Goal: given a GitHub repo, hand the user a working public URL, a short test report, and any app logins. Never fork or modify the user's repo; work on a scratch copy.

## Preconditions
- The Cloudflare connector (tools named `mcp__Cloudflare_Developer_Platform__*`) is connected. Load its tools with ToolSearch if they are deferred. Call `workers_list` first: it proves the account is reachable without any token and shows existing Worker names, so you never overwrite one the user did not mean to replace. Pick a free name (repo name, lowercase).
- Uploading a build is the one thing the connector cannot do (it only lists and reads Workers). That step uses `wrangler`, which needs `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from environment secrets. If they are missing, stop after the local test, say deployment needs them, and do not ask for them in chat. If the user pastes them anyway, use them for this run only, never write them to a file or commit them, and remind the user to rotate them.
- The repo is reachable. Attach it with `add_repo` (read access) and clone it.

## Steps
1. Clone into a scratch dir (not the user's working tree). Detect the package manager from the lockfile and install.
2. Run it locally (dev server) and drive it with headless Chromium (playwright-core, executablePath /opt/pw-browsers/chromium). Visit each main route, click primary controls, and record any `pageerror` or console errors. Real bugs found this way are the point of the exercise; report them with file and cause.
3. If the app needs storage (database, key-value, files), create it with the connector (`d1_database_create`, `kv_namespace_create`, `r2_bucket_create`), add the binding to `wrangler.jsonc`, and seed demo data with `d1_database_query` so there are logins to report. Search `search_cloudflare_documentation` when unsure how a framework maps onto Workers.
4. Deploy with `scripts/deploy.sh <repo-dir> <worker-name>`. It picks the right path: Next.js uses `@opennextjs/cloudflare` plus wrangler; static or Vite apps deploy their build output as Worker assets.
5. Confirm with `workers_get_worker` (the new name appears with a fresh modified time), then curl the `https://<name>.<account-subdomain>.workers.dev` URL (expect 200) and re-run the browser smoke test against it if the container can reach it.
6. Reply with: the URL, what was tested, bugs found (with suggested fixes), logins, and cleanup notes.

## Credentials to report
Only report logins that exist: seeded demo users from the repo's README, seed scripts, or env examples. If the app needs a database or third-party keys you do not have, say what is missing instead of inventing values.

## Safety
- Workers URLs are public. Say so, and offer Cloudflare Access or deleting the Worker (`npx wrangler delete --name <worker>`, and delete any D1, KV or R2 resources the skill created via the connector).
- Never commit tokens. Add `.open-next` and `.wrangler` to a scratch .gitignore only.
- Pushing changes back to the user's repo, or opening a PR, needs their explicit ask.
