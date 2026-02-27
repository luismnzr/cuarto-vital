# Eclipse — Studio Management Platform

A white-label Ruby on Rails application for boutique fitness studios (yoga, Pilates, barre, etc.). Each client gets their own cloned instance with a custom-designed interface built on top of a solid black-and-white base.

> **This README is the architectural blueprint.** It is written so that an AI coding agent (Claude Code) can read it and build the entire application from scratch. Every section describes _what_ to build, _why_, and the expected behavior. Design mockups and Figma files will be provided separately during implementation.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture & Conventions](#3-architecture--conventions)
4. [Data Model](#4-data-model)
5. [Roles & Permissions](#5-roles--permissions)
6. [Core Features — Student-Facing Pages](#6-core-features--student-facing-pages)
7. [Core Features — Admin Dashboard](#7-core-features--admin-dashboard)
8. [Core Features — Teacher Views](#8-core-features--teacher-views)
9. [Payments — Stripe Integration](#9-payments--stripe-integration)
10. [Notifications — Email System](#10-notifications--email-system)
11. [Third-Party Integrations — WellHub / Fitpass](#11-third-party-integrations--wellhub--fitpass)
12. [Theming & Client Customization](#12-theming--client-customization)
13. [Deployment — Heroku (Per Client)](#13-deployment--heroku-per-client)
14. [Future Roadmap](#14-future-roadmap)
15. [Development Setup](#15-development-setup)
16. [Cloning Workflow for New Clients](#16-cloning-workflow-for-new-clients)

---

## 1. Product Overview

Eclipse is a studio management platform purpose-built for boutique fitness businesses. Studios use it to manage classes, sell packages/subscriptions, handle reservations with waitlists, and track their business from an admin dashboard.

**What makes Eclipse different:** every client gets a fully custom UI designed by a UI/UX designer (the repo maintainer). The codebase is a black-and-white, unstyled but fully functional base. For each new client, the repo is cloned, a custom theme/design layer is applied, and it's deployed as an independent Heroku app.

### Core Value Proposition

- **For studio owners (admin):** A complete management tool — classes, packages, subscriptions, reservations, revenue tracking, user management.
- **For students:** A clean, intuitive interface to browse classes, buy packages, make reservations, and manage their account.
- **For teachers:** A focused view of their schedule and class rosters.

---

## 2. Tech Stack

| Layer               | Technology                                    | Notes                                                           |
| ------------------- | --------------------------------------------- | --------------------------------------------------------------- |
| **Framework**       | Ruby on Rails 7.2+                            | Monolith, server-rendered                                       |
| **Frontend**        | Hotwire (Turbo + Stimulus)                    | SPA-like feel without a JS framework                            |
| **Styling**         | Tailwind CSS 3.x                              | shadcn/ui-inspired component patterns (ported to ViewComponent) |
| **Components**      | ViewComponent                                 | Reusable UI components following shadcn design tokens           |
| **Database**        | PostgreSQL 16                                 | One database per client instance                                |
| **Authentication**  | Devise                                        | With three roles (student, teacher, admin)                      |
| **Authorization**   | Pundit                                        | Policy-based, role-aware                                        |
| **Background Jobs** | Sidekiq + Redis                               | Waitlist processing, email delivery, Stripe webhooks            |
| **Payments**        | Stripe (Checkout + Customer Portal + Connect) | Each client uses their own Stripe account                       |
| **Email**           | Action Mailer + Postmark (or SendGrid)        | Transactional emails                                            |
| **File Storage**    | Active Storage + S3                           | Studio logos, teacher photos, etc.                              |
| **Caching**         | Redis (shared with Sidekiq)                   | Fragment caching for schedules                                  |
| **Deployment**      | Heroku                                        | One app per client, separate Postgres + Redis add-ons           |
| **CI**              | GitHub Actions                                | Test suite runs on every push                                   |

### Why Hotwire + ViewComponent (not React)

The custom UI for each client is applied at the _template and component level_, not via a JS theme system. Hotwire with ViewComponent gives us server-rendered HTML where every component (buttons, cards, modals, form inputs) is a Ruby class with a corresponding ERB template that can be overridden per-client. Tailwind utility classes are applied directly. This keeps the stack simple, fast, and easy for the designer to customize without a build step.

### shadcn-Inspired Component Library

We don't use shadcn/ui directly (it's React-based). Instead, we replicate the shadcn design philosophy in ViewComponent:

- A base set of unstyled/minimally-styled components in `app/components/ui/`
- Each component uses Tailwind classes and follows shadcn's design tokens (spacing, border radius, color variables)
- CSS custom properties defined in `app/assets/stylesheets/theme.css` allow per-client color theming
- Components: `ButtonComponent`, `CardComponent`, `BadgeComponent`, `DialogComponent`, `InputComponent`, `SelectComponent`, `TableComponent`, `AvatarComponent`, `AlertComponent`, `DropdownComponent`, `TabsComponent`, `ToastComponent`

---

## 3. Architecture & Conventions

### Directory Structure

```
app/
├── components/
│   └── ui/                     # shadcn-inspired ViewComponents
│       ├── button_component.rb
│       ├── button_component.html.erb
│       ├── card_component.rb
│       ├── ...
│       └── theme.css           # CSS custom properties for theming
├── controllers/
│   ├── application_controller.rb
│   ├── pages_controller.rb           # Static pages (home, about, terms)
│   ├── classes_controller.rb         # Class browsing and reservation
│   ├── packages_controller.rb        # Package browsing and purchase
│   ├── subscriptions_controller.rb   # Subscription management
│   ├── reservations_controller.rb    # Reservation CRUD
│   ├── profiles_controller.rb        # User profile and settings
│   ├── sessions_controller.rb        # Devise overrides
│   ├── webhooks/
│   │   └── stripe_controller.rb      # Stripe webhook handler
│   ├── admin/
│   │   ├── dashboard_controller.rb
│   │   ├── users_controller.rb
│   │   ├── classes_controller.rb
│   │   ├── packages_controller.rb
│   │   ├── subscriptions_controller.rb
│   │   ├── reservations_controller.rb
│   │   ├── teachers_controller.rb
│   │   ├── settings_controller.rb
│   │   ├── reports_controller.rb
│   │   └── shop/
│   │       ├── products_controller.rb
│   │       └── orders_controller.rb
│   └── teacher/
│       ├── dashboard_controller.rb
│       ├── classes_controller.rb
│       └── roster_controller.rb
├── models/
│   ├── user.rb                 # Devise model with role enum
│   ├── studio_class.rb         # A scheduled class (avoiding 'Class' keyword)
│   ├── class_template.rb       # Reusable class definition (name, style, level)
│   ├── reservation.rb          # Student ↔ StudioClass join + status
│   ├── waitlist_entry.rb       # Ordered waitlist per class
│   ├── package.rb              # Credit-based class package
│   ├── user_package.rb         # A purchased package instance
│   ├── subscription_plan.rb    # Unlimited access plan definition
│   ├── user_subscription.rb    # Active subscription instance
│   ├── class_credit.rb         # Tracks credit usage per reservation
│   ├── payment.rb              # Payment record (Stripe reference)
│   ├── studio_setting.rb       # Key-value studio configuration
│   ├── category.rb             # Class categories (yoga, pilates, etc.)
│   ├── page.rb                 # Custom CMS-lite pages (admin-created)
│   ├── product.rb              # Shop items
│   ├── order.rb                # Shop orders
│   └── order_item.rb           # Line items
├── policies/                   # Pundit policies
├── jobs/
│   ├── waitlist_promotion_job.rb
│   ├── reservation_reminder_job.rb
│   ├── package_expiration_job.rb
│   └── stripe_webhook_job.rb
├── mailers/
│   ├── reservation_mailer.rb
│   ├── package_mailer.rb
│   ├── waitlist_mailer.rb
│   └── reminder_mailer.rb
├── views/
│   ├── layouts/
│   │   ├── application.html.erb       # Student layout
│   │   ├── admin.html.erb             # Admin layout
│   │   └── teacher.html.erb           # Teacher layout
│   ├── pages/
│   ├── classes/
│   ├── packages/
│   ├── profiles/
│   ├── admin/
│   └── teacher/
└── javascript/
    └── controllers/            # Stimulus controllers
        ├── reservation_controller.js
        ├── schedule_controller.js
        ├── countdown_controller.js
        ├── toast_controller.js
        ├── dropdown_controller.js
        └── dialog_controller.js
```

### Naming Conventions

- **Model names:** `StudioClass` (not `Class`), `ClassTemplate`, `UserPackage`, etc.
- **Routes:** RESTful. Admin routes namespaced under `/admin`, teacher under `/teacher`.
- **Stimulus controllers:** Named after their UI behavior, not business logic.
- **ViewComponents:** Named with `Component` suffix, placed in `app/components/ui/`.

### Key Patterns

- **Service Objects** in `app/services/` for complex business logic (e.g., `ReservationService`, `WaitlistService`, `PackagePurchaseService`, `CreditDeductionService`).
- **Form Objects** using `ActiveModel::Model` for multi-step forms.
- **Turbo Frames** for dynamic sections (class schedule, reservation actions, waitlist status).
- **Turbo Streams** for real-time updates (spots remaining, waitlist position).
- **Broadcast** class availability changes via Action Cable → Turbo Streams.

---

## 4. Data Model

### Entity Relationship Summary

```
User (student/teacher/admin)
├── has_many :reservations
├── has_many :waitlist_entries
├── has_many :user_packages
├── has_one  :user_subscription
└── has_many :payments

ClassTemplate
├── belongs_to :category
├── has_many :studio_classes
└── name, style, level, description, default_duration, default_capacity

StudioClass
├── belongs_to :class_template
├── belongs_to :teacher (User where role: :teacher)
├── has_many :reservations
├── has_many :waitlist_entries
└── date, start_time, end_time, duration, capacity, status

Reservation
├── belongs_to :user
├── belongs_to :studio_class
├── belongs_to :class_credit (optional)
└── status: [confirmed, cancelled, completed, no_show]

WaitlistEntry
├── belongs_to :user
├── belongs_to :studio_class
└── position, joined_at, promoted_at, status

Package
├── has_many :user_packages
└── name, price, credit_count, expiration_days, description, active

UserPackage
├── belongs_to :user
├── belongs_to :package
├── has_many :class_credits
└── purchased_at, expires_at, credits_remaining

SubscriptionPlan
├── has_many :user_subscriptions
└── name, price, interval (monthly/annual), stripe_price_id, active

UserSubscription
├── belongs_to :user
├── belongs_to :subscription_plan
└── stripe_subscription_id, status, current_period_start, current_period_end

ClassCredit
├── belongs_to :user_package
├── has_one :reservation
└── used_at

Payment
├── belongs_to :user
└── stripe_payment_intent_id, amount, currency, status, description

StudioSetting
└── key, value (singleton key-value store)

Category
├── has_many :class_templates
└── name, slug, description, sort_order

Page (for custom studio pages)
└── title, slug, body (ActionText), published, sort_order

Product
├── has_many :order_items
└── name, description, price, stock_quantity, active, image (ActiveStorage)

Order
├── belongs_to :user (optional — can be walk-in)
├── has_many :order_items
└── total, status, notes, stripe_payment_intent_id

OrderItem
├── belongs_to :order
├── belongs_to :product
└── quantity, unit_price
```

### Migration Details

All models should have appropriate indexes, particularly:

- `reservations`: composite index on `[user_id, studio_class_id]` with uniqueness constraint (prevent double booking)
- `waitlist_entries`: composite index on `[user_id, studio_class_id]` with uniqueness constraint
- `waitlist_entries`: index on `[studio_class_id, position]` for ordered retrieval
- `studio_classes`: index on `[date, start_time]` for schedule queries
- `user_packages`: index on `[user_id, expires_at]` for active package lookups
- `studio_settings`: unique index on `key`

### StudioSetting Default Keys

These settings are managed by admin and drive application behavior:

| Key                          | Default                 | Description                                                |
| ---------------------------- | ----------------------- | ---------------------------------------------------------- |
| `studio_name`                | `"Studio"`              | Display name                                               |
| `studio_email`               | `""`                    | Contact email                                              |
| `studio_phone`               | `""`                    | Contact phone                                              |
| `studio_address`             | `""`                    | Physical address                                           |
| `studio_timezone`            | `"America/Mexico_City"` | Timezone for all scheduling                                |
| `cancellation_window_hours`  | `12`                    | Hours before class start when cancellation forfeits credit |
| `late_cancel_forfeit_credit` | `true`                  | Whether late cancellations lose the credit                 |
| `waitlist_enabled`           | `true`                  | Enable/disable waitlist globally                           |
| `max_waitlist_size`          | `5`                     | Maximum waitlist spots per class                           |
| `booking_window_days`        | `14`                    | How far in advance students can book                       |
| `currency`                   | `"mxn"`                 | Default currency                                           |
| `shop_enabled`               | `false`                 | Enable/disable the shop module                             |

---

## 5. Roles & Permissions

Three roles managed via an enum on the `User` model:

```ruby
enum role: { student: 0, teacher: 1, admin: 2 }
```

### Student

- Browse schedule, view class details
- Purchase packages and subscriptions
- Make/cancel reservations (respecting cancellation window)
- Join waitlists
- View their own profile, package balance, class history, billing
- Access public pages (home, about, terms, custom pages)

### Teacher

- Everything a student can do (teachers can also take classes)
- View their own teaching schedule
- View class rosters for classes they teach
- Mark attendance (confirm / no-show) for their classes

### Admin

- Full access to everything
- Dashboard with studio analytics
- CRUD for classes, class templates, categories
- CRUD for packages and subscription plans
- Manage all users (view, edit role, deactivate)
- Manage reservations (override cancellation policy, manual booking)
- Manage studio settings
- Manage custom pages
- Manage shop products and orders
- View revenue reports and class utilization

### Pundit Policy Pattern

Every controller action should have a corresponding Pundit policy. Use `after_action :verify_authorized` in the application controller to ensure nothing slips through.

---

## 6. Core Features — Student-Facing Pages

### 6.1 Home Page (`/`)

The landing page for the studio. Content is studio-specific and will be customized per client. The base template should include:

- Hero section (image + headline + CTA)
- Brief studio description
- Upcoming classes preview (next 3–5 classes, Turbo Frame for dynamic loading)
- Featured packages/pricing CTA
- Footer with studio info, social links, and navigation

### 6.2 Class Schedule & Reservation (`/classes`)

**Schedule View:**

- Default view: weekly schedule, starting on current day
- Display classes as time-blocked cards showing: class name, teacher name, time, duration, spots remaining, level badge, category badge
- Filter by: category, style, level, teacher, day of week
- Color-code by category or style (configurable via admin)
- Turbo Frame: clicking a class card opens a detail panel/modal

**Class Detail (show page or modal):**

- Full class info: name, teacher (with photo), description, style, level, time, duration
- Spots remaining / full indicator
- **Reserve button** → triggers `ReservationService`:
  1. Check if user is logged in (redirect to login if not)
  2. Check if user has available credits (active package with remaining credits) or an active subscription
  3. If package user: deduct one credit via `CreditDeductionService`, create reservation
  4. If subscription user: create reservation directly (unlimited)
  5. If no credits/subscription: redirect to packages page with a message
  6. Confirm reservation, send confirmation email
- **Waitlist button** (if class is full and waitlist enabled):
  1. Add user to waitlist with next position number
  2. Show waitlist position to user
  3. Send waitlist confirmation email
- **Cancel reservation button** (if already reserved):
  1. Check cancellation window (`cancellation_window_hours` setting)
  2. If within window: cancel and restore credit (package users)
  3. If outside window (late cancel): cancel but forfeit credit (if `late_cancel_forfeit_credit` is true)
  4. After cancellation: trigger `WaitlistPromotionJob` to promote next waitlist entry
  5. Send cancellation confirmation email

**Waitlist Promotion Logic (`WaitlistPromotionJob`):**

1. When a spot opens (cancellation or capacity increase), find the earliest `pending` waitlist entry for that class
2. Check if the waitlisted user still has credits/subscription
3. If yes: create reservation, deduct credit, update waitlist entry status to `promoted`, send promotion email
4. If no: skip to next waitlist entry, mark skipped entry as `expired`
5. Continue until spot is filled or waitlist is exhausted

### 6.3 Class Packages (`/packages`)

**Display:**

- List all active packages with: name, price, number of classes, expiration period, description
- List all active subscription plans with: name, monthly/annual price, description
- Clear distinction between credit packages and unlimited subscriptions
- **Purchase button** → redirects to Stripe Checkout (see Section 9)

### 6.4 User Profile (`/profile`)

**Sections (navigable via tabs or sidebar):**

- **Overview:** Name, email, member since, current package/subscription status
- **My Classes:** Upcoming reservations with cancel option, past classes (history)
- **My Package:** Current package with credits remaining, expiration date, purchase history
- **My Subscription:** Current plan, next billing date, manage subscription (→ Stripe Customer Portal)
- **Waitlists:** Current waitlist positions with option to leave waitlist
- **Billing:** Payment history, receipts (from Stripe), manage payment method (→ Stripe Customer Portal)
- **Settings:** Edit name, email, password, notification preferences
- **Delete Account:** With confirmation flow

### 6.5 About Page (`/about`)

Static content page. Base template with sections for studio story, team/teachers, location. Fully customized per client.

### 6.6 Terms & Conditions (`/terms`)

Static content page. Can use ActionText for admin-editable content or be hardcoded per client.

### 6.7 Custom Pages (`/pages/:slug`)

Admin-created pages using ActionText rich text editor. Used for studio-specific content (teacher bios, FAQ, workshops, special events).

### 6.8 Authentication

**Devise configuration:**

- `/login` — Email + password
- `/signup` — Name, email, password, password confirmation
- `/password/reset` — Email-based reset flow
- Session-based authentication (not JWT — server-rendered app)
- Optional: OmniAuth for Google sign-in (future enhancement)

**After sign up:**

- Send welcome email
- Redirect to home or classes page (not a blank dashboard)

---

## 7. Core Features — Admin Dashboard

All admin views are under the `/admin` namespace with the `admin.html.erb` layout.

### 7.1 Dashboard (`/admin`)

A single-page overview with key metrics:

- **Today's snapshot:** Classes today, total reservations today, revenue today
- **This week/month:** Total classes, total reservations, new signups, revenue
- **Quick stats cards:** Total active students, active packages, active subscriptions, waitlist entries
- **Charts (Chartkick or similar):**
  - Revenue over time (last 30 days / 12 months)
  - Reservations over time
  - Class utilization (% capacity filled, averaged)
  - Most popular classes / teachers
- **Recent activity feed:** Last 10 reservations, cancellations, purchases

### 7.2 User Management (`/admin/users`)

- Searchable, sortable, paginated table of all users
- Columns: name, email, role, signup date, active package/subscription, total classes attended
- Filters: role, has active package, has active subscription, signup date range
- **User detail:** Full profile view + admin actions:
  - Change role
  - Manually assign a package (gift/comp)
  - View all reservations and payment history
  - Deactivate account

### 7.3 Class Management (`/admin/classes`)

**Class Templates (`/admin/class-templates`):**

- CRUD for reusable class definitions
- Fields: name, category, style, level, description, default duration, default capacity, image

**Schedule (`/admin/classes`):**

- Calendar or list view of all scheduled classes
- Create new class from template: select template, assign teacher, set date/time, override duration/capacity if needed
- Bulk scheduling: create recurring classes (e.g., "Every Monday and Wednesday at 7am for the next 8 weeks")
- Edit/cancel individual class instances
- View class roster and waitlist
- Mark attendance after class

**Categories (`/admin/categories`):**

- CRUD for class categories
- Name, description, sort order

### 7.4 Package & Subscription Management (`/admin/packages`)

**Packages:**

- CRUD for credit packages
- Fields: name, price, credit count, expiration days, description, active toggle
- Cannot delete packages that have active user purchases (soft-deactivate instead)

**Subscription Plans:**

- CRUD for subscription plans
- Fields: name, price, billing interval (monthly/annual), description, active toggle
- Linked to Stripe Price objects (admin enters `stripe_price_id` or it's created via API)

### 7.5 Reservation Management (`/admin/reservations`)

- Searchable table of all reservations
- Filters: date range, class, teacher, status (confirmed/cancelled/completed/no-show)
- Admin can: manually create reservation for a student, cancel with credit restore override, move student between classes

### 7.6 Studio Settings (`/admin/settings`)

Form-based interface for all `StudioSetting` keys (see Section 4). Organized into logical groups:

- Studio Information (name, email, phone, address, timezone)
- Booking Rules (cancellation window, waitlist settings, booking window)
- Payment (currency, Stripe configuration status)
- Features (shop enabled, etc.)

### 7.7 Shop Management (`/admin/shop`) — v1: Dashboard Only

**Products:**

- CRUD for products: name, description, price, stock quantity, image, active toggle
- No student-facing storefront in v1 — admin records sales manually

**Orders:**

- Admin creates orders from the dashboard (walk-in sales)
- Select products, quantities, optionally assign to a student user
- Record payment (cash, card via Stripe terminal, or mark as paid)
- Order history with filters

### 7.8 Reports (`/admin/reports`)

- Revenue breakdown: packages vs subscriptions vs shop
- Class utilization report: average fill rate per class template, per teacher, per time slot
- Student retention: new vs returning students, package renewal rate
- Export to CSV

---

## 8. Core Features — Teacher Views

Under the `/teacher` namespace with the `teacher.html.erb` layout. Teachers also have access to all student-facing pages.

### 8.1 Teacher Dashboard (`/teacher`)

- Today's classes with times and student count
- This week's schedule
- Quick access to class rosters

### 8.2 My Classes (`/teacher/classes`)

- Calendar or list view of their teaching schedule
- Click into a class to see the roster

### 8.3 Class Roster (`/teacher/classes/:id/roster`)

- List of confirmed students with name and photo
- Waitlist (if any)
- Attendance marking: confirm attendance or mark as no-show
- No-show triggers: no credit restoration (student loses the credit)

---

## 9. Payments — Stripe Integration

### Architecture: Stripe Connect (Standard)

Each studio client creates their own Stripe account. The Eclipse base app uses **Stripe Connect** in standard mode — the studio is the connected account, and the platform (Eclipse) has read/write access for API operations.

During client onboarding, the studio owner completes Stripe Connect OAuth to link their account.

### Payment Flows

**Package Purchase:**

1. Student clicks "Buy" on a package
2. App creates a Stripe Checkout Session with the package price, linked to the studio's connected account
3. Student completes payment on Stripe's hosted checkout page
4. Stripe redirects back to success URL
5. Stripe sends `checkout.session.completed` webhook
6. `StripeWebhookJob` creates `Payment` record and `UserPackage` with full credits
7. Confirmation email sent

**Subscription Purchase:**

1. Student clicks "Subscribe" on a plan
2. App creates a Stripe Checkout Session in `subscription` mode with the plan's `stripe_price_id`
3. After successful checkout, Stripe creates a recurring subscription
4. Webhook creates `Payment` and `UserSubscription` records
5. Subsequent billing is handled automatically by Stripe
6. `invoice.paid` webhook keeps `UserSubscription` current period updated
7. `customer.subscription.deleted` webhook deactivates the subscription

**Subscription Management:**

- "Manage Subscription" button redirects to Stripe Customer Portal (billing, cancel, update payment method)
- Portal events come back via webhooks

### Webhook Events to Handle

| Event                           | Action                                            |
| ------------------------------- | ------------------------------------------------- |
| `checkout.session.completed`    | Create Payment, fulfill package or subscription   |
| `invoice.paid`                  | Update subscription period, create payment record |
| `invoice.payment_failed`        | Notify user, mark subscription as past_due        |
| `customer.subscription.updated` | Sync status changes                               |
| `customer.subscription.deleted` | Deactivate user subscription                      |

### Webhook Security

- Verify webhook signatures using the endpoint secret
- Process webhooks idempotently (use Stripe event ID to prevent duplicates)
- Use Sidekiq for async processing — return 200 immediately, process in background

### Environment Variables (per client)

```
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECT_ACCOUNT_ID=acct_...  # If using Connect
```

---

## 10. Notifications — Email System

### Mailer Configuration

Use Action Mailer with Postmark (or SendGrid) as the delivery method. Each client instance has its own sending domain/API key.

### Email Templates (all should have studio branding via layout)

| Trigger                     | Recipient             | Content                                                       |
| --------------------------- | --------------------- | ------------------------------------------------------------- |
| Sign up                     | Student               | Welcome email with quick start guide                          |
| Reservation confirmed       | Student               | Class name, date, time, location, cancellation policy         |
| Reservation cancelled       | Student               | Confirmation of cancellation, credit restored (if applicable) |
| Waitlist joined             | Student               | Position number, class details                                |
| Waitlist promoted           | Student               | "You're in!" — class details, credit deducted                 |
| Waitlist expired            | Student               | Class has passed without promotion                            |
| Class reminder              | Student               | 2 hours before class (configurable) — class details           |
| Package purchased           | Student               | Package details, credit balance, expiration date              |
| Package expiring soon       | Student               | 3 days before expiration — remaining credits, renewal CTA     |
| Package expired             | Student               | Credits lost, link to purchase new package                    |
| Subscription confirmed      | Student               | Plan details, next billing date                               |
| Subscription renewal failed | Student               | Payment failed, update payment method CTA                     |
| No-show recorded            | Student               | Notification that credit was not restored                     |
| Class cancelled (by admin)  | All reserved students | Apology, credit restored automatically                        |

### Background Jobs for Scheduled Emails

- `ReservationReminderJob` — Runs hourly, finds classes starting in 2 hours, sends reminders to confirmed students
- `PackageExpirationWarningJob` — Runs daily, finds packages expiring in 3 days, sends warning
- `PackageExpirationJob` — Runs daily at midnight (studio timezone), expires packages past their date

---

## 11. Third-Party Integrations — WellHub / Fitpass

### Overview

WellHub (formerly Gympass) and Fitpass are corporate wellness aggregator platforms. Employees of partner companies can access fitness studios through these platforms. Studios need to validate check-ins and reconcile payments with the aggregator.

### Integration Architecture

Create an `ExternalCheckin` model and a generic integration adapter pattern:

```ruby
# app/models/external_checkin.rb
# Fields: user_identifier, platform (wellhub/fitpass), studio_class_id,
#         checked_in_at, validated, external_reference_id

# app/services/integrations/base_adapter.rb
# app/services/integrations/wellhub_adapter.rb
# app/services/integrations/fitpass_adapter.rb
```

### v1 Scope

- **Admin can record external check-ins** from the dashboard (manual entry per class)
- Admin selects the platform, enters the user identifier / reference code
- External check-ins appear in reports separately from direct bookings
- Admin can export external check-in data for reconciliation with the platform

### Future Scope

- API integration with WellHub and Fitpass for automated check-in validation
- QR code scanning for walk-in check-ins
- Automatic reconciliation reports

---

## 12. Theming & Client Customization

### The Customization Layer

Each client clone is customized at three levels:

**Level 1 — Theme Variables (`app/assets/stylesheets/theme.css`)**

```css
:root {
  /* Base colors — override per client */
  --color-primary: #000000;
  --color-primary-foreground: #ffffff;
  --color-secondary: #f5f5f5;
  --color-secondary-foreground: #000000;
  --color-accent: #000000;
  --color-accent-foreground: #ffffff;
  --color-background: #ffffff;
  --color-foreground: #000000;
  --color-muted: #f5f5f5;
  --color-muted-foreground: #737373;
  --color-border: #e5e5e5;
  --color-destructive: #ef4444;

  /* Typography */
  --font-sans: "Inter", system-ui, sans-serif;
  --font-heading: var(--font-sans);

  /* Spacing & Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
}
```

**Level 2 — ViewComponent Templates**

Override individual component templates in a client-specific directory or directly in the component ERB files. The base components are designed to be minimal and composable.

**Level 3 — Page Templates**

Full page layouts and view templates can be customized per client. The base templates provide the structure; the client fork modifies the visual design.

### Static Assets Per Client

- `app/assets/images/logo.svg` — Studio logo
- `app/assets/images/og-image.png` — Open Graph image
- `public/favicon.ico` — Favicon

### Studio Configuration Seed

Each client gets a `db/seeds/studio.rb` file:

```ruby
StudioSetting.upsert_all([
  { key: 'studio_name', value: 'My Yoga Studio' },
  { key: 'studio_timezone', value: 'America/Mexico_City' },
  { key: 'cancellation_window_hours', value: '12' },
  # ... etc
])
```

---

## 13. Deployment — Heroku (Per Client)

### One Heroku App Per Client

Each client gets:

- A Heroku app (e.g., `eclipse-studio-name`)
- Heroku Postgres (Standard 0 or higher for production)
- Heroku Redis (for Sidekiq + caching)
- Custom domain (e.g., `app.studiodomain.com`)
- SSL via Heroku ACM (automatic)

### Procfile

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate
```

### Required Environment Variables

```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<from credentials>
SECRET_KEY_BASE=<generated>

# Database (auto-set by Heroku Postgres)
DATABASE_URL=postgres://...

# Redis (auto-set by Heroku Redis)
REDIS_URL=redis://...

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email
POSTMARK_API_KEY=...
MAILER_FROM_ADDRESS=hello@studiodomain.com
MAILER_FROM_NAME=Studio Name

# Storage
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_BUCKET=eclipse-studio-name
AWS_REGION=us-east-1

# App
APP_HOST=app.studiodomain.com
STUDIO_NAME=Studio Name
```

### Deployment Checklist for New Client

1. Clone repo → new private GitHub repo for client
2. Apply custom theme and design
3. Create Heroku app with addons (Postgres, Redis)
4. Set all environment variables
5. Connect GitHub repo to Heroku for auto-deploy
6. Run `heroku run rails db:migrate`
7. Run `heroku run rails db:seed`
8. Configure custom domain and SSL
9. Set up Stripe webhook endpoint pointing to `https://app.studiodomain.com/webhooks/stripe`
10. Send onboarding email to studio owner

---

## 14. Future Roadmap

These features are **not in v1** but the architecture should accommodate them without major refactoring.

### 14.1 Student-Facing Shop / E-commerce

- Public shop page (`/shop`) where students can browse and purchase products
- Cart system with Stripe Checkout
- Order tracking and delivery status
- Currently v1 is admin-dashboard-only for recording walk-in sales

### 14.2 Digital Studio / Video Library

- Studios can upload pre-recorded classes
- Students can access on-demand classes with an active subscription
- Video hosting via MUX or Vimeo (external service)
- New model: `VideoClass` linked to `ClassTemplate`

### 14.3 Automated WellHub / Fitpass Integration

- Full API integration for check-in validation
- QR code scanning
- Automated reconciliation

### 14.4 Mobile App (React Native or PWA)

- Push notifications for class reminders
- Offline schedule viewing
- Consider PWA first for faster rollout

### 14.5 Multi-Location Support

- Studios with multiple locations
- Location selector, per-location schedules
- New model: `Location` with has_many `:studio_classes`

### 14.6 Teacher Self-Service

- Teachers manage their own availability
- Sub request system (teacher can request a substitute)

---

## 15. Development Setup

### Prerequisites

- Ruby 3.3+
- Rails 7.2+
- PostgreSQL 16+
- Redis 7+
- Node.js 20+ (for Tailwind and asset pipeline)
- Stripe CLI (for local webhook testing)

### Quick Start

```bash
# Clone the repo
git clone git@github.com:your-org/eclipse-base.git
cd eclipse-base

# Install dependencies
bundle install
yarn install

# Setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed    # Seeds default studio settings, admin user, sample data

# Start services
bin/dev              # Uses Procfile.dev to start Rails, Sidekiq, Tailwind watcher

# In a separate terminal, for Stripe webhook testing:
stripe listen --forward-to localhost:3000/webhooks/stripe
```

### Default Seed Data

The seed file should create:

- Admin user: `admin@eclipse.dev` / `password` (development only)
- Teacher user: `teacher@eclipse.dev` / `password`
- Student user: `student@eclipse.dev` / `password`
- Sample categories: Yoga, Pilates, Meditation
- Sample class templates
- Sample packages (5-class, 10-class, 20-class)
- Sample subscription plan (monthly unlimited)
- 2 weeks of sample scheduled classes
- Default studio settings

### Test Suite

```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system

# Run specific test file
bin/rails test test/models/reservation_test.rb
```

Use Minitest (Rails default) with FactoryBot for test data and Capybara for system tests.

---

## 16. Cloning Workflow for New Clients

This is the step-by-step process for setting up a new studio client:

```
1. CLONE
   └── Fork eclipse-base → eclipse-[client-name]

2. CONFIGURE
   ├── Update db/seeds/studio.rb with client info
   ├── Set environment variables
   └── Connect Stripe account

3. DESIGN
   ├── Update theme.css with client brand colors and fonts
   ├── Replace logo, favicon, and OG image
   ├── Customize page templates and component styles
   └── Add any client-specific custom pages

4. DEPLOY
   ├── Create Heroku app + addons
   ├── Push to Heroku
   ├── Run migrations and seeds
   └── Configure domain + SSL

5. ONBOARD
   ├── Create admin account for studio owner
   ├── Set up initial packages and subscription plans
   ├── Set up class templates and schedule
   └── Train studio staff on admin dashboard
```

---

## Appendix: Key Business Rules Summary

| Rule                                   | Details                                                        |
| -------------------------------------- | -------------------------------------------------------------- |
| **One reservation per class per user** | Enforced at DB level (unique index)                            |
| **Credit deduction**                   | 1 credit per reservation, restored on timely cancellation      |
| **Cancellation window**                | Configurable (default 12h). Late cancel = forfeit credit       |
| **Subscription = unlimited**           | No credit tracking, just verify active subscription            |
| **Waitlist order**                     | Strictly FIFO, auto-promote on cancellation                    |
| **Waitlist promotion**                 | Checks if user still has credits/subscription before promoting |
| **Package expiration**                 | Calendar-based from purchase date (e.g., 30 days)              |
| **No-show**                            | Marked by teacher, credit is not restored                      |
| **Class cancellation (by admin)**      | All students notified, all credits restored                    |
| **Timezone**                           | All times stored in UTC, displayed in studio timezone          |
| **Currency**                           | Configurable per studio, passed to Stripe                      |
