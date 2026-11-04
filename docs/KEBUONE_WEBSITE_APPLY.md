# kebuone-website — apply these changes (agent could not push to that repo)

## Option A — apply patch (recommended)

In your **`kebuone-website`** clone on your PC:

```bash
git checkout main
git pull origin main
git checkout -b launch/evuddy-backend-alignment
git apply --check /path/to/evuddy_app/docs/kebuone-launch-alignment.patch
git apply /path/to/evuddy_app/docs/kebuone-launch-alignment.patch
git add -A
git commit -m "Launch: Evuddy branding, helpdesk fix, fleet planner, cron checklist"
git push -u origin launch/evuddy-backend-alignment
```

Open a PR on GitHub → merge → deploy EC2.

The patch file lives in **`evuddy_app`** after you merge PR #69:

`docs/kebuone-launch-alignment.patch`

## What the patch includes

- Razorpay `create-order` merchant name **Evuddy**
- Rental end reminder: correct helpdesk **+91 8726006519** (was 6512)
- SMS/email copy **Evuddy** (MSG91 sender ID still **EVUDDY**)
- Business Planner panel + `fleetPartnerCalc.ts` + deposit refund queue on tickets
- `docs/LAUNCH_CHECKLIST.md` — GitHub `CRON_SECRET`, EC2 deploy, health check

## After merge on kebuone-website

1. **GitHub → Settings → Secrets → Actions**: set `CRON_SECRET` and optional `SITE_URL=https://www.evuddy.com`
2. **EC2**: same `CRON_SECRET` in env; `git pull`, `npm ci`, `npm run build`, restart app
3. Verify `https://www.evuddy.com/api/health` → `unpaidJob.stale: false`

See **`docs/LAUNCH_CHECKLIST.md`** inside the patch for full detail.
