# Eclipse - New Client Setup Guide

A step-by-step walkthrough for cloning and configuring Eclipse for a new boutique fitness studio client. This guide assumes you have the base repo ready and have deployed at least once before.

---

## Table of Contents

1. [Overview: What Makes Each Client Unique](#1-overview-what-makes-each-client-unique)
2. [Before You Start (Gather Client Info)](#2-before-you-start-gather-client-info)
3. [Step 1: Clone the Repo](#3-step-1-clone-the-repo)
4. [Step 2: Create the Heroku App](#4-step-2-create-the-heroku-app)
5. [Step 3: Set Up Third-Party Accounts](#5-step-3-set-up-third-party-accounts)
6. [Step 4: Configure Environment Variables](#6-step-4-configure-environment-variables)
7. [Step 5: Deploy](#7-step-5-deploy)
8. [Step 6: Customize Branding (Colors & Logo)](#8-step-6-customize-branding-colors--logo)
9. [Step 7: Configure Studio Settings](#9-step-7-configure-studio-settings)
10. [Step 8: Set Up the Studio's Classes & Pricing](#10-step-8-set-up-the-studios-classes--pricing)
11. [Step 9: Domain & Email DNS](#11-step-9-domain--email-dns)
12. [Step 10: Post-Launch Verification Checklist](#12-step-10-post-launch-verification-checklist)
13. [Quick Reference: File Map](#13-quick-reference-file-map)
14. [Quick Reference: Environment Variables](#14-quick-reference-environment-variables)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Overview: What Makes Each Client Unique

Each client gets their own Heroku app running the same codebase. Here's what changes per client:

| Layer | What Changes | Where |
|-------|-------------|-------|
| **Infrastructure** | Heroku app, database, Redis | Heroku dashboard |
| **Payments** | Stripe account + API keys | Stripe dashboard + env vars |
| **Email** | Postmark server + sender domain | Postmark dashboard + env vars |
| **Branding** | Colors, logo, fonts | `theme.css` + `public/icon.png` |
| **Studio Info** | Name, address, phone, timezone | Admin panel (Studio Settings) |
| **Business Rules** | Cancellation policy, waitlist, currency | Admin panel (Studio Settings) |
| **Classes** | Templates, categories, schedule, teachers | Admin panel |
| **Pricing** | Packages & subscription plans | Admin panel + Stripe |
| **Domain** | Custom domain + SSL | Heroku + DNS provider |
| **Wellhub** (optional) | Partner integration | Env vars + Admin panel |

**What stays the same:** The codebase, deployment pipeline, background job definitions, and all application logic.

---

## 2. Before You Start (Gather Client Info)

Before touching any code or dashboards, collect this from your client:

### Must Have

- [ ] **Studio name** (e.g., "Zen Flow Studio")
- [ ] **Contact email** (e.g., hello@zenflow.com)
- [ ] **Phone number** (e.g., +52 55 9876 5432)
- [ ] **Physical address** (e.g., "Calle Durango 145, Roma Norte, CDMX")
- [ ] **Timezone** (e.g., `America/Mexico_City`, `America/New_York`)
- [ ] **Currency** (e.g., `mxn`, `usd`)
- [ ] **Domain name** (e.g., app.zenflow.com) — purchased and DNS access available
- [ ] **Brand colors** — at minimum a primary color and accent color
- [ ] **Logo** — SVG preferred, plus a 512x512 PNG for the app icon
- [ ] **Class types they offer** (e.g., Yoga, Pilates, Barre, Cycling)
- [ ] **Pricing** — packages (5-class, 10-class, etc.) and/or unlimited subscriptions

### Nice to Have

- [ ] **Google Workspace** set up for business email (for MX records)
- [ ] **Cancellation policy** — how many hours before class? Forfeit credits on late cancel?
- [ ] **Waitlist preferences** — enabled? max size per class?
- [ ] **Booking window** — how many days in advance can students book?
- [ ] **Wellhub/Gympass** — are they a partner? (need API credentials from Wellhub)

---

## 3. Step 1: Clone the Repo

Each client gets their own copy of the Eclipse codebase. Clone the base repo into a new directory named after the client:

```bash
# Clone the base repo
git clone https://github.com/luismnzr/eclipse-v1.git zenflow-studio
cd zenflow-studio

# Remove the git history so this client starts fresh
rm -rf .git
git init
git add .
git commit -m "Initial commit — Eclipse base for Zen Flow Studio"
```

### Optional: Push to a Client-Specific Repo

If you want each client to have their own GitHub repo (recommended for tracking client-specific changes):

```bash
# Create a new repo on GitHub first (e.g., luismnzr/zenflow-studio), then:
git remote add origin https://github.com/luismnzr/zenflow-studio.git
git branch -M main
git push -u origin main
```

If you prefer to deploy all clients from the same repo (simpler, but branding changes affect the repo), you can skip creating a separate repo and just add the Heroku remote directly in the next step.

### Verify Local Setup

Make sure the app runs locally before deploying:

```bash
bundle install
rails db:create db:migrate db:seed
bin/dev
```

Visit `http://localhost:3000` — you should see the default Eclipse app with sample data.

---

## 4. Step 2: Create the Heroku App

Each client gets a separate Heroku app with its own database and Redis instance.

```bash
# Pick a clear app name (lowercase, hyphens)
CLIENT_NAME="zenflow-studio"

# Create the app
heroku create $CLIENT_NAME

# Add PostgreSQL
heroku addons:create heroku-postgresql:essential-0 -a $CLIENT_NAME

# Add Redis (for Sidekiq background jobs + caching)
heroku addons:create heroku-redis:mini -a $CLIENT_NAME

# Set the Ruby buildpack
heroku buildpacks:set heroku/ruby -a $CLIENT_NAME
```

Heroku auto-sets `DATABASE_URL` and `REDIS_URL` — you don't need to configure those manually.

---

## 5. Step 3: Set Up Third-Party Accounts

You need accounts on three services per client. Do these in parallel while other things spin up.

### 4a. Stripe (Payments)

1. Go to [dashboard.stripe.com](https://dashboard.stripe.com)
2. Either create a new Stripe account for this client, or use Stripe Connect
3. Switch to **Live mode** (toggle at top of dashboard)
4. Go to **Developers > API Keys**
5. Copy the **Publishable key** (`pk_live_...`) and **Secret key** (`sk_live_...`)
6. Go to **Developers > Webhooks > Add endpoint**
   - URL: `https://app.clientdomain.com/webhooks/stripe`
   - Events to listen for:
     - `checkout.session.completed`
     - `invoice.paid`
     - `invoice.payment_failed`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`
   - Copy the **Signing secret** (`whsec_...`)

> **Note:** You can set the webhook URL with a temporary Heroku domain first (`https://zenflow-studio-abc123.herokuapp.com/webhooks/stripe`) and update it later when the custom domain is ready.

### 4b. Postmark (Email)

1. Go to [account.postmarkapp.com](https://account.postmarkapp.com)
2. Create a new **Server** for this client (e.g., "Zen Flow Studio")
3. Copy the **Server API Token**
4. Go to **Sender Signatures > Add Domain** and add the client's domain
5. You'll get DNS records to add later (DKIM + Return-Path) — note them down

### 4c. AWS S3 (File Storage — Optional)

Only needed if the studio will upload photos (teacher headshots, class images, etc.). If not needed right away, skip this — the app falls back to local storage.

1. Create an S3 bucket (e.g., `eclipse-zenflow`)
2. Create an IAM user with S3 access to that bucket
3. Save the access key ID and secret

---

## 6. Step 4: Configure Environment Variables

This is the core of per-client configuration. Set all of these on the Heroku app:

```bash
CLIENT_NAME="zenflow-studio"

# === REQUIRED ===

# Rails
heroku config:set RAILS_ENV=production -a $CLIENT_NAME
heroku config:set SECRET_KEY_BASE=$(rails secret) -a $CLIENT_NAME
heroku config:set RAILS_MASTER_KEY=<paste from config/master.key> -a $CLIENT_NAME

# Domain
heroku config:set APP_HOST=app.zenflow.com -a $CLIENT_NAME

# Stripe (from Step 2a)
heroku config:set STRIPE_SECRET_KEY=sk_live_xxx -a $CLIENT_NAME
heroku config:set STRIPE_PUBLISHABLE_KEY=pk_live_xxx -a $CLIENT_NAME
heroku config:set STRIPE_WEBHOOK_SECRET=whsec_xxx -a $CLIENT_NAME

# Postmark (from Step 2b)
heroku config:set POSTMARK_API_TOKEN=xxx -a $CLIENT_NAME
heroku config:set MAILER_FROM_ADDRESS=hello@zenflow.com -a $CLIENT_NAME
```

```bash
# === OPTIONAL ===

# S3 Storage (from Step 2c)
heroku config:set AWS_ACCESS_KEY_ID=AKIA... -a $CLIENT_NAME
heroku config:set AWS_SECRET_ACCESS_KEY=xxx -a $CLIENT_NAME
heroku config:set AWS_BUCKET=eclipse-zenflow -a $CLIENT_NAME
heroku config:set AWS_REGION=us-east-1 -a $CLIENT_NAME
heroku config:set STORAGE_PREFIX=zenflow -a $CLIENT_NAME

# Wellhub (only if the studio uses Gympass/Wellhub)
heroku config:set WELLHUB_API_KEY=xxx -a $CLIENT_NAME
heroku config:set WELLHUB_WEBHOOK_SECRET=xxx -a $CLIENT_NAME
heroku config:set WELLHUB_API_URL=https://api.partners.gympass.com -a $CLIENT_NAME
heroku config:set WELLHUB_GYM_ID=xxx -a $CLIENT_NAME
```

### Where is `RAILS_MASTER_KEY`?

It's in `config/master.key` in your local repo (gitignored). This key decrypts `config/credentials.yml.enc`. All clients sharing the same codebase use the same master key unless you generate separate credentials per client.

---

## 7. Step 5: Deploy

```bash
CLIENT_NAME="zenflow-studio"

# Add this client as a git remote
heroku git:remote -a $CLIENT_NAME -r $CLIENT_NAME

# Deploy (pushes the same codebase)
git push $CLIENT_NAME main

# The Procfile release phase auto-runs db:migrate
```

After deploy, seed the database and start the background worker:

```bash
# Seed default data (admin user, sample categories, etc.)
heroku run rails db:seed -a $CLIENT_NAME

# Start the Sidekiq background worker
heroku ps:scale worker=1 -a $CLIENT_NAME
```

**Default seed credentials** (change these immediately after first login):
- Admin: `admin@eclipse.dev` / `password`
- Teacher: `teacher@eclipse.dev` / `password`
- Student: `student@eclipse.dev` / `password`

> **Important:** Log in as admin and change the admin password right away. Then create real user accounts for the client's staff.

---

## 8. Step 6: Customize Branding (Colors & Logo)

### 7a. Colors — `app/assets/stylesheets/theme.css`

This is the single file that controls the entire color palette. Open it and update the CSS variables to match the client's brand:

```css
:root {
  /* Primary — the main brand color (buttons, links, navbar accents) */
  --color-primary: #6366f1;
  --color-primary-foreground: #ffffff;
  --color-primary-hover: #4f46e5;

  /* Accent — secondary brand color (CTAs, highlights) */
  --color-accent: #8b5cf6;
  --color-accent-foreground: #ffffff;

  /* You can usually leave these defaults alone: */
  --color-background: #ffffff;
  --color-foreground: #0f172a;
  --color-secondary: #f1f5f9;
  --color-muted: #f8fafc;
  --color-border: #e2e8f0;
}
```

**For most clients, you only need to change 3 values:**
1. `--color-primary` — their brand color
2. `--color-primary-hover` — a slightly darker shade
3. `--color-accent` — a complementary accent color

**Example — a studio with teal branding:**
```css
--color-primary: #0d9488;
--color-primary-foreground: #ffffff;
--color-primary-hover: #0f766e;
--color-accent: #14b8a6;
```

### 7b. Logo & Icons

Replace these files with the client's branding:

| File | Size/Format | Used For |
|------|-------------|----------|
| `public/icon.png` | 512x512 PNG | PWA icon, browser tab |
| `public/icon.svg` | SVG | Scalable icon |

The navbar currently uses an inline SVG icon. To use the client's logo, you can update the navbar partial at `app/views/shared/_navbar.html.erb`.

### 7c. Fonts (Optional)

The default font is Inter. To change it, update `--font-sans` in `theme.css`:

```css
--font-sans: "Outfit", system-ui, sans-serif;
```

And add the font import to `app/views/layouts/application.html.erb` (in the `<head>` section).

### 7d. Commit the Branding Changes

After updating colors/logo, commit and redeploy:

```bash
git add app/assets/stylesheets/theme.css public/icon.png public/icon.svg
git commit -m "Customize branding for Zen Flow Studio"
git push $CLIENT_NAME main
```

---

## 9. Step 7: Configure Studio Settings

Studio settings are stored in the database and can be managed two ways:

### Option A: Admin Panel (Recommended)

1. Go to `https://app.zenflow.com/admin/settings`
2. Fill in all fields:
   - **Studio Name** — "Zen Flow Studio"
   - **Email** — hello@zenflow.com
   - **Phone** — +52 55 9876 5432
   - **Address** — Calle Durango 145, Roma Norte, CDMX
   - **Timezone** — America/Mexico_City
   - **Currency** — mxn (or usd, eur, etc.)
   - **Cancellation Window** — hours before class (e.g., 12)
   - **Late Cancel Forfeit** — whether late cancels lose their credit
   - **Waitlist** — enabled/disabled, max size
   - **Booking Window** — how many days in advance (e.g., 14)

### Option B: Rails Console

```bash
heroku run rails console -a zenflow-studio
```

```ruby
StudioSetting.set("studio_name", "Zen Flow Studio")
StudioSetting.set("studio_email", "hello@zenflow.com")
StudioSetting.set("studio_phone", "+52 55 9876 5432")
StudioSetting.set("studio_address", "Calle Durango 145, Roma Norte, CDMX")
StudioSetting.set("studio_timezone", "America/Mexico_City")
StudioSetting.set("currency", "mxn")
StudioSetting.set("cancellation_window_hours", "8")
StudioSetting.set("late_cancel_forfeit_credit", "true")
StudioSetting.set("waitlist_enabled", "true")
StudioSetting.set("max_waitlist_size", "5")
StudioSetting.set("booking_window_days", "14")
StudioSetting.set("shop_enabled", "false")
StudioSetting.set("wellhub_enabled", "false")
```

### All Available Settings

| Setting | Default | What It Controls |
|---------|---------|-----------------|
| `studio_name` | "Studio" | Displayed in navbar, footer, emails, page titles |
| `studio_email` | "" | Footer, about page, email templates |
| `studio_phone` | "" | Footer, about page |
| `studio_address` | "" | Footer, about page, class reminder emails |
| `studio_timezone` | "America/Mexico_City" | All class times & scheduling logic |
| `currency` | "mxn" | Pricing display & Stripe checkout currency |
| `cancellation_window_hours` | "12" | How many hours before class a student can cancel |
| `late_cancel_forfeit_credit` | "true" | If true, late cancels lose their credit |
| `waitlist_enabled` | "true" | Global on/off for the waitlist feature |
| `max_waitlist_size` | "5" | Max students on a waitlist per class |
| `booking_window_days` | "14" | How far in advance students can book |
| `shop_enabled` | "false" | Toggle the product shop feature |
| `wellhub_enabled` | "false" | Toggle Wellhub/Gympass integration |

---

## 10. Step 8: Set Up the Studio's Classes & Pricing

This is all done through the admin panel after deployment. The seed data provides sample classes to get started, but you'll want to configure these for the real studio.

### 9a. Categories

Go to `/admin/categories` and set up the class types the studio offers.

**Examples:** Yoga, Pilates, Barre, Cycling, Meditation, Strength

The seed data creates Yoga, Pilates, and Meditation. Edit or delete these as needed.

### 9b. Class Templates

Go to `/admin/class_templates` and create reusable class definitions.

Each template defines:
- **Name** — "Power Vinyasa", "Barre Basics"
- **Category** — links to a category
- **Style** — e.g., "Vinyasa", "Reformer"
- **Level** — beginner, intermediate, advanced, all_levels
- **Duration** — in minutes (e.g., 60)
- **Default Capacity** — max students per class

### 9c. Scheduled Classes

Go to `/admin/classes` to schedule actual classes from templates.

Each scheduled class needs:
- **Template** — which class type
- **Teacher** — who's teaching
- **Date & Time** — when
- **Capacity** — can override the template default

The system also has a `GenerateScheduledClassesJob` that runs daily at 2am to auto-create recurring classes.

### 9d. Teachers

Go to `/admin/users`, create accounts with the **teacher** role. Teachers can then:
- View their schedule at `/teacher`
- Mark attendance for their classes
- Update their bio and photo

### 9e. Packages (Credit Packs)

Go to `/admin/packages` and create the studio's pricing tiers.

Each package has:
- **Name** — "5 Class Pack"
- **Price** — in the studio's currency (e.g., 750.00 for MXN)
- **Credits** — number of classes included
- **Expiration** — days until the package expires (e.g., 30)

### 9f. Subscription Plans (Unlimited)

Go to `/admin/subscription_plans` and set up unlimited access plans.

Each plan needs:
- **Name** — "Monthly Unlimited"
- **Price** — recurring price
- **Interval** — monthly or annual
- **Stripe Price ID** — create the product in Stripe first, then paste the `price_xxx` ID here

> **Important:** Subscriptions require a matching product/price in Stripe. Create the product in your Stripe dashboard first, copy the Price ID, and enter it when creating the subscription plan in the admin panel.

---

## 11. Step 9: Domain & Email DNS

### 10a. Add Custom Domain to Heroku

```bash
heroku domains:add app.zenflow.com -a zenflow-studio
# Heroku will output a DNS target like: xxx.herokudns.com

# Enable automatic SSL
heroku certs:auto:enable -a zenflow-studio
```

### 10b. DNS Records to Add

Go to the client's DNS provider (Cloudflare, Namecheap, GoDaddy, etc.) and add:

| Type | Host | Value | Purpose |
|------|------|-------|---------|
| CNAME | `app` | `xxx.herokudns.com` (from Heroku) | Points domain to Heroku |
| TXT | `_dmarc` | `v=DMARC1; p=none;` | Email authentication |
| TXT | *(from Postmark)* | *(from Postmark)* | DKIM verification |
| CNAME | *(from Postmark)* | *(from Postmark)* | Return-Path for email delivery |
| MX | `@` | Google Workspace MX records | Business email (if using Google Workspace) |

### 10c. Update Stripe Webhook URL

Once the custom domain is live, go back to Stripe and update your webhook endpoint URL:
- From: `https://zenflow-studio-xxx.herokuapp.com/webhooks/stripe`
- To: `https://app.zenflow.com/webhooks/stripe`

### 10d. Verify Postmark Domain

Once DNS records propagate (usually 15-60 minutes), go back to Postmark and verify the domain. Check the "Sender Signatures" page — it should show green checkmarks for DKIM and Return-Path.

---

## 12. Step 10: Post-Launch Verification Checklist

Run through every item before handing the studio over to the client:

### Core App
- [ ] App loads at `https://app.zenflow.com`
- [ ] Studio name, address, and contact info display correctly in navbar and footer
- [ ] Brand colors look correct throughout the site
- [ ] Logo/icon appears correctly

### Authentication
- [ ] New user can sign up
- [ ] Welcome email arrives (check Postmark activity)
- [ ] User can log in
- [ ] Password reset flow works

### Classes & Booking
- [ ] Class schedule shows on `/classes`
- [ ] Student can reserve a class (with a package credit)
- [ ] Reservation confirmation email arrives
- [ ] Student can cancel a reservation within the cancellation window
- [ ] Waitlist works (if enabled) — fill a class, then have someone join the waitlist

### Payments
- [ ] Buying a package redirects to Stripe Checkout
- [ ] Payment completes and credits appear in the student's profile
- [ ] Stripe webhook events are being received (check Stripe Dashboard > Webhooks)
- [ ] Subscription purchase works (if subscription plans exist)
- [ ] Customer portal accessible from student profile for subscription management

### Admin Panel
- [ ] Admin can access `/admin`
- [ ] Dashboard shows metrics
- [ ] Can create/edit classes
- [ ] Can view and manage users
- [ ] Settings page reflects correct studio info
- [ ] Reports page loads

### Teacher Portal
- [ ] Teacher can log in and see `/teacher`
- [ ] Teacher sees their scheduled classes
- [ ] Teacher can mark attendance on class roster

### Background Jobs
- [ ] Sidekiq worker is running (`heroku ps -a zenflow-studio` should show `worker` running)
- [ ] Scheduled jobs are registered:
  ```bash
  heroku run rails runner "puts Sidekiq::Cron::Job.all.map(&:name)" -a zenflow-studio
  ```
- [ ] Class reminder emails are sent (2 hours before class)

### Wellhub (If Enabled)
- [ ] `StudioSetting.wellhub_enabled?` returns `true`
- [ ] Webhook endpoint responds at `/webhooks/wellhub`
- [ ] Schedule sync is running (check Sidekiq logs)

---

## 13. Quick Reference: File Map

Files you'll touch per client:

| File | What to Change | When |
|------|---------------|------|
| `app/assets/stylesheets/theme.css` | Brand colors, fonts | Every client |
| `public/icon.png` | App icon (512x512) | Every client |
| `public/icon.svg` | SVG icon | Every client |
| `app/views/shared/_navbar.html.erb` | Logo in navbar (if using image instead of SVG) | If client has a logo |
| `db/seeds.rb` | Seed data (only if you want client-specific seeds) | Optional |

Files you should **not** need to change:
- Controllers, models, services — the app logic is the same for all clients
- Layouts and views — they pull from StudioSetting and theme.css
- Email templates — they use StudioSetting helpers automatically
- Background jobs — same schedule for everyone

---

## 14. Quick Reference: Environment Variables

### Required (Every Client)

| Variable | Example | How to Get It |
|----------|---------|--------------|
| `RAILS_ENV` | `production` | Always "production" |
| `RAILS_MASTER_KEY` | `abc123...` | From `config/master.key` in your repo |
| `SECRET_KEY_BASE` | `long-random-string` | Run `rails secret` |
| `APP_HOST` | `app.zenflow.com` | Client's domain |
| `STRIPE_SECRET_KEY` | `sk_live_...` | Stripe Dashboard > API Keys |
| `STRIPE_PUBLISHABLE_KEY` | `pk_live_...` | Stripe Dashboard > API Keys |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` | Stripe Dashboard > Webhooks |
| `POSTMARK_API_TOKEN` | `xxx` | Postmark > Server > API Tokens |
| `MAILER_FROM_ADDRESS` | `hello@zenflow.com` | Client's preferred sender email |

### Auto-Set by Heroku

| Variable | Set By |
|----------|--------|
| `DATABASE_URL` | heroku-postgresql addon |
| `REDIS_URL` | heroku-redis addon |

### Optional

| Variable | When Needed |
|----------|------------|
| `AWS_ACCESS_KEY_ID` | If using S3 for file uploads |
| `AWS_SECRET_ACCESS_KEY` | If using S3 for file uploads |
| `AWS_BUCKET` | If using S3 for file uploads |
| `AWS_REGION` | If using S3 (default: us-east-1) |
| `STORAGE_PREFIX` | If sharing one S3 bucket across clients |
| `WELLHUB_API_KEY` | If studio uses Wellhub/Gympass |
| `WELLHUB_WEBHOOK_SECRET` | If studio uses Wellhub/Gympass |
| `WELLHUB_API_URL` | If studio uses Wellhub/Gympass |
| `WELLHUB_GYM_ID` | If studio uses Wellhub/Gympass |
| `RAILS_LOG_LEVEL` | To change log verbosity (default: info) |

---

## 15. Troubleshooting

### App won't start

```bash
# Check logs
heroku logs --tail -a zenflow-studio

# Common causes:
# - Missing RAILS_MASTER_KEY → credentials can't be decrypted
# - Missing SECRET_KEY_BASE → Rails won't boot in production
# - Database not migrated → should auto-run via Procfile release phase
```

### Emails not sending

```bash
# Check Postmark activity log for delivery status
# Common causes:
# - POSTMARK_API_TOKEN not set or wrong
# - Sender domain not verified in Postmark (DNS records missing)
# - MAILER_FROM_ADDRESS doesn't match a verified sender
```

### Stripe payments failing

```bash
# Check Stripe Dashboard > Webhooks > Recent Events
# Common causes:
# - STRIPE_WEBHOOK_SECRET wrong → webhook signature validation fails
# - Webhook URL not updated to custom domain
# - Stripe still in test mode (keys start with pk_test_ / sk_test_)
```

### Background jobs not running

```bash
# Check if worker dyno is running
heroku ps -a zenflow-studio

# If no worker:
heroku ps:scale worker=1 -a zenflow-studio

# Check if Redis is connected
heroku config:get REDIS_URL -a zenflow-studio
```

### Classes not generating automatically

```bash
# Check if the cron job is registered
heroku run rails runner "puts Sidekiq::Cron::Job.all.map(&:name)" -a zenflow-studio

# Manually trigger class generation
heroku run rails runner "GenerateScheduledClassesJob.perform_now" -a zenflow-studio
```

### Wrong timezone on class schedule

Check both:
1. `StudioSetting.get("studio_timezone")` — should match the client's timezone
2. `config/application.rb` — has `config.time_zone` set to "Central Time (US & Canada)" by default

The StudioSetting timezone is what the app uses for display. Update it via admin panel or console.

---

## Summary: The 10-Step Checklist

For quick reference, here's the high-level flow:

1. **Clone the repo** — fresh copy for the client, optionally push to a new GitHub repo
2. **Create Heroku app** + PostgreSQL + Redis
3. **Set up Stripe** (keys + webhook) + **Postmark** (server + domain)
4. **Set environment variables** on Heroku
5. **Deploy** (`git push`) + seed + scale worker
6. **Customize theme.css** with client's brand colors + replace icons
7. **Configure Studio Settings** via admin panel (name, address, timezone, currency, policies)
8. **Set up classes** — categories, templates, teachers, schedule, packages, subscriptions
9. **Configure DNS** — point domain to Heroku, add email DNS records, update Stripe webhook URL
10. **Verify** — run through the checklist before handing off to the client
