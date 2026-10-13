# FoodShutter web companion

Next.js 16 / React 19 application for reviewing meals in Supabase, with Tailwind CSS 4, Recharts, Framer Motion, SWR and theme selection.

[Overview](../README.md) · [Setup](../docs/getting-started.md#4-start-the-web-companion) · [Capability status](../docs/architecture.md#capability-status)

## Run locally

```bash
cp .env.example .env.local
npm ci
npm run dev
```

Run from `web/`. In PowerShell use `Copy-Item .env.example .env.local`. Configure your own Supabase project, then open `http://localhost:3000`.

| Variable | Purpose |
| --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public browser anon key |

These values are browser-visible. Never supply a service-role key. Configure `/auth/callback` redirects and the login providers separately.

## Pages

| Route | Behavior |
| --- | --- |
| `/` | Product landing page |
| `/login`, `/auth/callback` | Supabase authentication |
| `/dashboard` | Intake summary and recent meals |
| `/history`, `/history/[id]` | Meal history and detail |
| `/stats` | Weekly/monthly calorie visualization |
| `/nutrition`, `/nutrition/[id]` | Nutrition-search interface |
| `/suggestions` | Current sample messages |
| `/settings` | Theme and web nutrition goals |
| `/about` | Application information |

Meal browsing reads `meals` and `dishes`. Settings use `user_profiles` and `nutrition_goals`, distinct from the mobile `profiles` contract. Provision tables and policies independently; no migrations are supplied.

## Edge Function scaffolding

`python-proxy` calls `${PYTHON_BACKEND_URL}/search`. The current FastAPI application lacks that route, so search needs a matching service implementation. `stats-aggregate` references `history_logs`, while the active chart adapter reads meals and dishes directly.

## Validation and limits

```bash
npm run lint
npm run build
```

There is no committed web test suite. Suggestions return fixed messages; account deletion displays an alert; public photo URLs need reconciliation with private Storage. Calendar aggregation and the assumption that the first history group represents today need validation. See [release requirements](../docs/deployment.md).

Framework code changes must follow [AGENTS.md](AGENTS.md), including consulting documentation shipped with the installed Next.js version.
