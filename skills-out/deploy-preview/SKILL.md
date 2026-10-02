---
name: deploy-preview
description: Clone a GitHub repo (no fork), install it, smoke-test it in a headless browser, deploy it to Cloudflare Workers, and return a public preview URL plus any login credentials. Use whenever the user shares a GitHub repo (owner/repo or URL) and wants it run, tested, previewed, hosted, or "put on Cloudflare" so they can open it on their phone, even if they never say "deploy".
---

# deploy-preview

Goal: given a GitHub repo, hand the user a working public URL, a short test report, and any app logins. Never fork or modify the user's repo; work on a scratch copy.

## Preconditions (check first, stop and tell the user if missing)
- `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` are set as environment variables. They must come from environment secrets. If the user pastes a token in chat, use it for this run only, never write it to a file or commit it, and remind them to rotate it.
- `curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/tokens/verify` returns success. If the host is blocked, the environment's network policy must allow api.cloudflare.com.
- The repo is reachable. Attach it with `add_repo` (read access) and clone it.

## Steps
1. Clone into a scratch dir (not the user's working tree). Detect the package manager from the lockfile and install.
2. Run it locally (dev server) and drive it with headless Chromium (playwright-core, executablePath /opt/pw-browsers/chromium). Visit each main route, click primary controls, and record any `pageerror` or console errors. Real bugs found this way are the point of the exercise; report them with file and cause.
3. Deploy with `scripts/deploy.sh <repo-dir> <worker-name>`. It picks the right path: Next.js uses `@opennextjs/cloudflare` plus wrangler; static or Vite apps deploy their build output as Worker assets. Worker name: lowercase repo name.
4. Verify the live URL with curl (expect 200), and re-run the browser smoke test against it if the container can reach it.
5. Reply with: the URL, what was tested, bugs found (with suggested fixes), logins, and cleanup notes.

## Credentials to report
Only report logins that exist: seeded demo users from the repo's README, seed scripts, or env examples. If the app needs a database or third-party keys you do not have, say what is missing instead of inventing values.

## Safety
- Workers URLs are public. Say so, and offer Cloudflare Access or deleting the Worker (`npx wrangler delete --name <worker>`).
- Never commit tokens. Add `.open-next` and `.wrangler` to a scratch .gitignore only.
- Pushing changes back to the user's repo, or opening a PR, needs their explicit ask.
