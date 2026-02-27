# Eclipse - Deployment & Setup Guide

Complete checklist for deploying Eclipse to production — whether it's your first instance or a new client clone.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Heroku App Setup](#2-heroku-app-setup)
3. [Database & Redis](#3-database--redis)
4. [Environment Variables](#4-environment-variables)
5. [Stripe Setup](#5-stripe-setup)
6. [Postmark (Email) Setup](#6-postmark-email-setup)
7. [Wellhub Setup (Optional)](#7-wellhub-setup-optional)
8. [File Storage (Optional)](#8-file-storage-optional)
9. [Domain & DNS](#9-domain--dns)
10. [Deploy](#10-deploy)
11. [Post-Deploy Verification](#11-post-deploy-verification)
12. [Studio Configuration](#12-studio-configuration)
13. [Cloning for a New Client](#13-cloning-for-a-new-client)

---

## 1. Prerequisites

Before starting, make sure you have:

- [ ] Heroku CLI installed and authenticated
- [ ] Stripe account (with live keys ready)
- [ ] Postmark account and verified sender domain
- [ ] PostgreSQL (provided by Heroku Postgres addon)
- [ ] Redis (provided by Heroku Redis addon)
- [ ] Domain name purchased and DNS access available
- [ ] Google Workspace configured (for business email)

---

## 2. Heroku App Setup

```bash
# Create the Heroku app (one per client)
heroku create studio-client-name

# Confirm buildpacks
heroku buildpacks:set heroku/ruby -a studio-client-name
```

The `Procfile` handles process types automatically:
- **web** — Puma web server
- **worker** — Sidekiq background jobs
- **release** — Runs `db:migrate` on every deploy

---

## 3. Database & Redis

```bash
# Add PostgreSQL
heroku addons:create heroku-postgresql:essential-0 -a studio-client-name

# Add Redis (for Sidekiq + ActionCable)
heroku addons:create heroku-redis:mini -a studio-client-name
```

Heroku automatically sets `DATABASE_URL` and `REDIS_URL` — no manual config needed for these two.

---

## 4. Environment Variables

### Required

```bash
# Rails
heroku config:set RAILS_ENV=production -a studio-client-name
heroku config:set RAILS_MASTER_KEY=<from config/master.key> -a studio-client-name
heroku config:set SECRET_KEY_BASE=$(rails secret) -a studio-client-name

# Application
heroku config:set APP_HOST=app.clientdomain.com -a studio-client-name

# Stripe (see Section 5)
heroku config:set STRIPE_SECRET_KEY=sk_live_xxx -a studio-client-name
heroku config:set STRIPE_PUBLISHABLE_KEY=pk_live_xxx -a studio-client-name
heroku config:set STRIPE_WEBHOOK_SECRET=whsec_xxx -a studio-client-name

# Postmark (see Section 6)
heroku config:set POSTMARK_API_TOKEN=xxx -a studio-client-name
heroku config:set MAILER_FROM_ADDRESS=hello@clientdomain.com -a studio-client-name
```

### Optional

```bash
# Wellhub (see Section 7)
heroku config:set WELLHUB_API_KEY=xxx -a studio-client-name
heroku config:set WELLHUB_WEBHOOK_SECRET=xxx -a studio-client-name
heroku config:set WELLHUB_API_URL=https://api.partners.gympass.com -a studio-client-name
heroku config:set WELLHUB_GYM_ID=xxx -a studio-client-name

# Logging
heroku config:set RAILS_LOG_LEVEL=info -a studio-client-name
```

### Full Variable Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RAILS_ENV` | Yes | — | Must be `production` |
| `RAILS_MASTER_KEY` | Yes | — | From `config/master.key` |
| `SECRET_KEY_BASE` | Yes | — | Generate with `rails secret` |
| `APP_HOST` | Yes | `example.com` | Client's domain (e.g. `app.studio.com`) |
| `DATABASE_URL` | Auto | — | Set automatically by Heroku Postgres |
| `REDIS_URL` | Auto | — | Set automatically by Heroku Redis |
| `STRIPE_SECRET_KEY` | Yes | — | Stripe live secret key |
| `STRIPE_PUBLISHABLE_KEY` | Yes | — | Stripe live publishable key |
| `STRIPE_WEBHOOK_SECRET` | Yes | — | Stripe webhook signing secret |
| `POSTMARK_API_TOKEN` | Yes | — | Postmark server API token |
| `MAILER_FROM_ADDRESS` | Yes | `hello@eclipse.dev` | Sender email address |
| `WELLHUB_API_KEY` | No | — | Only if Wellhub integration is enabled |
| `WELLHUB_WEBHOOK_SECRET` | No | — | Only if Wellhub integration is enabled |
| `WELLHUB_API_URL` | No | `https://api.partners.gympass.com` | Wellhub API base URL |
| `WELLHUB_GYM_ID` | No | — | Can also be set via StudioSetting in DB |
| `RAILS_LOG_LEVEL` | No | `info` | Log verbosity |
| `RAILS_MAX_THREADS` | No | `5` | Puma/DB connection pool size |

---

## 5. Stripe Setup

### 5.1 Get API Keys

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Switch to **Live mode** (toggle at the top)
3. Copy the **Publishable key** (`pk_live_...`) and **Secret key** (`sk_live_...`)

### 5.2 Create Products & Prices

Create your subscription plans and packages in Stripe. You'll need the **Price IDs** (`price_xxx`) to configure:
- `subscription_plans.stripe_price_id` — for recurring subscriptions
- Package pricing is handled via checkout sessions at runtime

### 5.3 Configure Webhook

1. Go to [Stripe Webhooks](https://dashboard.stripe.com/webhooks)
2. Click **Add endpoint**
3. Set URL to: `https://app.clientdomain.com/webhooks/stripe`
4. Select these events:
   - `checkout.session.completed`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. Copy the **Signing secret** (`whsec_...`) and set it as `STRIPE_WEBHOOK_SECRET`

### 5.4 Stripe in the Database

These fields are managed automatically by the app — no manual setup needed:
- `users.stripe_customer_id` — created on first checkout
- `user_packages.stripe_payment_intent_id`
- `payments.stripe_payment_intent_id` / `stripe_checkout_session_id`
- `user_subscriptions.stripe_subscription_id` / `stripe_customer_id`

---

## 6. Postmark (Email) Setup

### 6.1 Create Server

1. Log in to [Postmark](https://account.postmarkapp.com)
2. Create a new **Server** for this client
3. Copy the **Server API Token**

### 6.2 Verify Sender Domain

1. Go to **Sender Signatures** > **Add Domain**
2. Add the client's domain (e.g. `clientdomain.com`)
3. Add the required DNS records (DKIM, Return-Path) — see Section 9

### 6.3 Set Environment Variables

```bash
heroku config:set POSTMARK_API_TOKEN=<server-api-token> -a studio-client-name
heroku config:set MAILER_FROM_ADDRESS=hello@clientdomain.com -a studio-client-name
```

### 6.4 Email Templates

The app sends emails for:
- User welcome / confirmation (`UserMailer`)
- Reservation confirmations & cancellations (`ReservationMailer`)
- Package purchase confirmations (`PackageMailer`)
- Waitlist notifications (`WaitlistMailer`)
- Subscription lifecycle events (`SubscriptionMailer`)
- Class reminders (`ReminderMailer`)

All use Rails views — no Postmark template configuration needed.

---

## 7. Wellhub Setup (Optional)

Only required if the studio participates in the Wellhub/Gympass network.

### 7.1 Register as Partner

Contact `integrations@gympass.com` to register as a CMS partner and receive:
- API Key
- Webhook Secret
- Gym ID for each studio location

### 7.2 Set Environment Variables

```bash
heroku config:set WELLHUB_API_KEY=xxx -a studio-client-name
heroku config:set WELLHUB_WEBHOOK_SECRET=xxx -a studio-client-name
heroku config:set WELLHUB_GYM_ID=xxx -a studio-client-name
```

### 7.3 Enable in Studio Settings

After deploy, enable Wellhub in the admin panel or directly in the database:
- Set `StudioSetting.wellhub_enabled = true`
- Optionally set `StudioSetting.wellhub_gym_id` (overrides the env var)

### 7.4 Register Webhooks

The `WellhubSetupService` will register the webhook URL (`https://app.clientdomain.com/webhooks/wellhub`) with the Wellhub API automatically.

Wellhub webhook events handled:
- `checkin` — Validate member check-ins
- `booking-requested` — Create bookings
- `booking-cancelled` — Cancel bookings
- `booking-checked-in` — Mark attendance
- `system-integration-requested` — Integration setup

### 7.5 Schedule Sync

The `WellhubScheduleSyncJob` runs every 30 minutes automatically via Sidekiq Cron to keep class schedules in sync.

---

## 8. File Storage (Optional)

By default, Active Storage uses **local disk**. For production with user uploads (profile photos, etc.), configure a cloud provider.

### AWS S3

1. Create an S3 bucket (e.g. `eclipse-clientname`)
2. Create an IAM user with S3 access
3. Add credentials to Rails encrypted credentials:

```bash
EDITOR=nano rails credentials:edit
```

```yaml
aws:
  access_key_id: AKIA...
  secret_access_key: xxx
  bucket: eclipse-clientname
  region: us-east-1
```

4. Update `config/environments/production.rb`:
```ruby
config.active_storage.service = :amazon
```

---

## 9. Domain & DNS

### 9.1 Heroku Custom Domain

```bash
heroku domains:add app.clientdomain.com -a studio-client-name
```

Heroku will provide a DNS target (e.g. `xxx.herokudns.com`).

### 9.2 DNS Records

Add these records at your DNS provider:

| Type | Host | Value | Purpose |
|------|------|-------|---------|
| CNAME | `app` | `xxx.herokudns.com` | Points app subdomain to Heroku |
| TXT | `_dmarc` | `v=DMARC1; p=none;` | Email authentication |
| TXT | (per Postmark) | (per Postmark) | DKIM for Postmark |
| CNAME | (per Postmark) | (per Postmark) | Return-Path for Postmark |
| MX | `@` | Google Workspace MX records | Business email (if using Google Workspace) |

### 9.3 SSL

Heroku provides automatic SSL via ACM (Automated Certificate Management):

```bash
heroku certs:auto:enable -a studio-client-name
```

---

## 10. Deploy

```bash
# Add Heroku remote
heroku git:remote -a studio-client-name

# Deploy
git push heroku main

# The release phase will auto-run migrations (see Procfile)
```

### First-Time Seed (if applicable)

```bash
heroku run rails db:seed -a studio-client-name
```

### Scale Workers

```bash
# Ensure the Sidekiq worker dyno is running
heroku ps:scale worker=1 -a studio-client-name
```

---

## 11. Post-Deploy Verification

Run through this checklist after every deployment:

### Application
- [ ] App loads at `https://app.clientdomain.com`
- [ ] User can sign up and receive confirmation email
- [ ] User can log in

### Payments
- [ ] Stripe checkout flow works (buy a package)
- [ ] Stripe webhook is receiving events (check Stripe Dashboard > Webhooks > Recent events)
- [ ] Stripe customer portal is accessible from user profile

### Email
- [ ] Welcome email arrives on signup
- [ ] Password reset email works
- [ ] Reservation confirmation email sends
- [ ] Check Postmark activity for delivery status

### Background Jobs
- [ ] Sidekiq dashboard accessible (if exposed)
- [ ] Scheduled jobs are registered (check `heroku run rails runner "puts Sidekiq::Cron::Job.all.map(&:name)"`)
- [ ] Class generation job produces upcoming classes

### Wellhub (if enabled)
- [ ] Webhook endpoint responds (`POST /webhooks/wellhub`)
- [ ] Schedule sync is running (check Sidekiq logs)

---

## 12. Studio Configuration

After deploy, configure the studio via admin panel or Rails console:

```bash
heroku run rails console -a studio-client-name
```

```ruby
setting = StudioSetting.instance

setting.update!(
  studio_name: "Client Studio Name",
  studio_email: "info@clientdomain.com",
  studio_phone: "+52 55 1234 5678",
  studio_address: "123 Studio Street, Mexico City",
  studio_timezone: "America/Mexico_City",
  currency: "mxn",
  cancellation_window_hours: 12,
  late_cancel_forfeit_credit: true,
  waitlist_enabled: true,
  max_waitlist_size: 5,
  booking_window_days: 14,
  shop_enabled: false,
  wellhub_enabled: false
)
```

---

## 13. Cloning for a New Client

When onboarding a new studio client:

1. **Create a new Heroku app** — each client gets their own instance
2. **Repeat Sections 2-10** of this guide with the client's details
3. **Unique per client:**
   - Heroku app name
   - Domain and DNS
   - Stripe account or connected account (keys)
   - Postmark server (API token) and verified sender domain
   - Wellhub Gym ID (if applicable)
   - Studio settings (name, email, phone, address, timezone, currency)
   - `RAILS_MASTER_KEY` — generate a new one per client or share across clones (your call)

4. **Shared across clients:**
   - The codebase (same repo, same branch)
   - Deployment pipeline (same `git push heroku main`)
   - Sidekiq job definitions and schedules

### Quick Clone Script

```bash
CLIENT_NAME="new-client"
CLIENT_DOMAIN="app.newclient.com"

# Create app + addons
heroku create $CLIENT_NAME
heroku addons:create heroku-postgresql:essential-0 -a $CLIENT_NAME
heroku addons:create heroku-redis:mini -a $CLIENT_NAME

# Set env vars
heroku config:set \
  RAILS_ENV=production \
  RAILS_MASTER_KEY=<master-key> \
  SECRET_KEY_BASE=$(rails secret) \
  APP_HOST=$CLIENT_DOMAIN \
  STRIPE_SECRET_KEY=sk_live_xxx \
  STRIPE_PUBLISHABLE_KEY=pk_live_xxx \
  STRIPE_WEBHOOK_SECRET=whsec_xxx \
  POSTMARK_API_TOKEN=xxx \
  MAILER_FROM_ADDRESS=hello@newclient.com \
  -a $CLIENT_NAME

# Add domain + SSL
heroku domains:add $CLIENT_DOMAIN -a $CLIENT_NAME
heroku certs:auto:enable -a $CLIENT_NAME

# Deploy
heroku git:remote -a $CLIENT_NAME -r $CLIENT_NAME
git push $CLIENT_NAME main

# Scale worker
heroku ps:scale worker=1 -a $CLIENT_NAME

# Seed + configure
heroku run rails db:seed -a $CLIENT_NAME
```

---

## Summary: What You Need Before Going Live

| Item | Where to Get It |
|------|----------------|
| Stripe live keys | [dashboard.stripe.com/apikeys](https://dashboard.stripe.com/apikeys) |
| Stripe webhook secret | [dashboard.stripe.com/webhooks](https://dashboard.stripe.com/webhooks) |
| Postmark API token | [account.postmarkapp.com](https://account.postmarkapp.com) |
| Domain name | Your registrar (Namecheap, Cloudflare, etc.) |
| DNS access | Your registrar or Cloudflare |
| Heroku account | [heroku.com](https://heroku.com) |
| Google Workspace | [workspace.google.com](https://workspace.google.com) |
| Wellhub credentials | `integrations@gympass.com` (optional) |
| Rails master key | `config/master.key` in your repo (gitignored) |
