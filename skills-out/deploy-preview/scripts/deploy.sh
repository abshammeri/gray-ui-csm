#!/usr/bin/env bash
# usage: deploy.sh <repo-dir> <worker-name>
set -euo pipefail
dir=$1; name=$2; cd "$dir"
: "${CLOUDFLARE_API_TOKEN:?set CLOUDFLARE_API_TOKEN}" "${CLOUDFLARE_ACCOUNT_ID:?set CLOUDFLARE_ACCOUNT_ID}"
pm=npm; [ -f pnpm-lock.yaml ] && pm=pnpm; [ -f yarn.lock ] && pm=yarn
if grep -q '"next"' package.json; then
  $pm add -D @opennextjs/cloudflare wrangler >/dev/null
  cat > wrangler.jsonc <<EOF
{ "name": "$name", "main": ".open-next/worker.js", "compatibility_date": "2025-04-01",
  "compatibility_flags": ["nodejs_compat","global_fetch_strictly_public"],
  "assets": { "directory": ".open-next/assets", "binding": "ASSETS" } }
EOF
  printf 'import { defineCloudflareConfig } from "@opennextjs/cloudflare";\nexport default defineCloudflareConfig();\n' > open-next.config.ts
  npx opennextjs-cloudflare build
else
  $pm install >/dev/null; $pm run build
  out=dist; [ -d build ] && out=build
  cat > wrangler.jsonc <<EOF
{ "name": "$name", "compatibility_date": "2025-04-01",
  "assets": { "directory": "$out", "not_found_handling": "single-page-application" } }
EOF
fi
npx wrangler deploy
