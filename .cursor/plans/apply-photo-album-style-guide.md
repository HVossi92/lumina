# Apply Photo Album Style Guide (Full App Consistency)

## Overview

Apply the Chelekom-inspired style guide from `photo-album-mockup/` across the **entire** Lumina app so that style and layout are consistent everywhere: theme/typography, sidebar layout, dashboard, orgs, albums, photos, upload, share, **auth (login, signup, reset, magic link, confirm)**, **admin (backup, manage orgs)**, **join organization**, and public share view.

**Branding:** Use **"Lumina"** everywhere. The mockup uses "SnapVault" – do not introduce SnapVault; all copy, logos, and titles are Lumina.

---

## Style Guide Summary (from photo-album-mockup/)

- **Fonts:** Source Sans 3 (sans), Playfair Display (serif), JetBrains Mono (mono)
- **Light theme:** Cream base (#faf6f1), dark green primary (#2d3a2e), brown secondary (#8b7355), goldenrod accent (#b8860b)
- **Dark theme:** Dark base (#1a1a18), warm primary (#d4c9b8), golden accent (#d4a017)
- **Layout:** Sidebar (Library/Manage), sticky header, `rounded-md` everywhere
- **Typography:** `font-serif` for headings, `font-mono` for dates/metadata
- **Components:** DaisyUI custom theme; `btn-accent` primary, `btn-ghost` secondary; inputs: `input input-bordered input-sm bg-base-200/60 border-base-300 rounded-md`

---

## 1. Theme and Typography (App-Wide Base)

- **assets/css/app.css:** Replace existing daisyUI light/dark themes with mockup palette (warm cream, green primary, goldenrod accent).
- **lib/lumina_web/components/layouts/root.html.heex:** Add Google Fonts (Source Sans 3, Playfair Display, JetBrains Mono), `theme-color` #2d3a2e, body classes for `font-sans` and antialiased.

All pages will inherit this base.

---

## 2. App Layout (Sidebar + Main)

- **lib/lumina_web/components/layouts.ex:** Replace navbar with sidebar + main:
  - Sidebar: Lumina logo (camera icon + "Lumina" font-serif), Library (Dashboard, contextual Albums), Manage (Upload, Share, Admin if admin), theme toggle, user avatar/email, Sign out.
  - Main: sticky header (breadcrumb or placeholder), content area `max-w-6xl p-4 sm:p-6 lg:p-8`.

**Layout variants:**

- **Authenticated:** Full sidebar + main; pass `current_user`, `current_scope` / org context.
- **Auth-only pages (sign-in, register, reset, magic link, confirm):** No sidebar – use a **centered card layout** (single column, card with same theme: `bg-base-200 border-base-300 rounded-md`), Lumina branding at top, consistent typography and `btn-accent` / `btn-ghost`.
- **Admin (backup, orgs):** Same authenticated sidebar + main; admin pages use same content styling (headings `font-serif`, forms/buttons from style guide).
- **Join organization:** Authenticated layout (sidebar + main); content area uses same card/form styling.
- **Public share view:** Minimal layout – small Lumina header only, no sidebar; body uses same theme and typography.

Ensure every LiveView that should show the app chrome uses `<Layouts.app flash={@flash} current_scope={...} current_user={@current_user}>` (or equivalent) and that auth/admin/join/share use the correct layout variant.

---

## 3. Page-by-Page Consistency

Apply the same design tokens and components to **every** screen.

### 3.1 Authenticated Main App

- **Dashboard** (`dashboard_live.ex`): `text-base-content` / `text-base-content/40`, `btn btn-accent`, org cards `bg-base-200 border-base-300 rounded-md`, `font-serif` title, empty state with icon + CTA.
- **Org Show** (`org_live/show.ex`): Same; album cards with aspect ratio, overlay, serif title.
- **Org New** (`org_live/new.ex`): Form with `<.input>` and DaisyUI input classes; `btn btn-accent` / `btn btn-ghost`.
- **Album Show** (`album_live/show.ex`): Breadcrumb, photo grid (aspect, rounded-md, hover overlay), same buttons and empty state.
- **Album New** (`album_live/new.ex`): Same form/button pattern.
- **Photo Upload** (`photo_live/upload.ex`): Drop zone and queue styled like mockup; `progress progress-accent`; same buttons.
- **Album Share** (`album_live/share.ex`): Same inputs and buttons; success state as `alert alert-success rounded-md`.

### 3.2 Auth (Login, Signup, Reset, Magic Link, Confirm)

- **Layout:** Centered card layout, no sidebar. Single column, Lumina branding at top.
- **Components:** All inputs use `input input-bordered ... bg-base-200/60 border-base-300 rounded-md`. Primary actions `btn btn-accent`, secondary `btn btn-ghost`. Headings `font-serif`.
- **Where:** AshAuthentication Phoenix components (sign-in, register, reset, magic link, confirm). Use **LuminaWeb.AuthOverrides** and/or override templates so that every auth page uses the same theme classes and centered layout. Ensure no page uses raw `gray-*` or `indigo-*`; use `base-content`, `accent`, etc.
- **Copy:** "Lumina" in titles/headers, not SnapVault or generic names.

### 3.3 Admin

- **Admin Backup** (`admin_live/backup.ex`): Replace `text-gray-*`, `bg-yellow-50`, `bg-indigo-600` with theme classes. Use `alert alert-warning rounded-md` for warning box; password input and buttons from style guide; heading `font-serif`.
- **Admin Orgs** (`admin_live/orgs.ex`): Tables/cards and forms use `base-200`, `base-300`, `btn-accent`, `btn-ghost`; headings `font-serif`; inputs same as rest of app. Consistent spacing and rounded-md.
- Both live under the same authenticated sidebar layout.

### 3.4 Join Organization

- **Join Live** (`join_live.ex`): Use Layouts.app (sidebar + main). Content: card/form styling, same input and button classes, `font-serif` headings, consistent empty/error states.

### 3.5 Public Share View

- **Share Live** (`share_live/show.ex`): Minimal layout (Lumina header only). Password form and photo grid use same theme and component styles as the rest of the app.

---

## 4. Core Components and Global Elements

- **core_components.ex:** Default `<.input>` and form styling to use DaisyUI theme classes when no custom class is passed. Flash: `alert-info` / `alert-error` with `rounded-md`.
- **layouts.ex:** Theme toggle and any global nav items use theme tokens. Logo/branding: **Lumina** (camera icon + "Lumina" text, font-serif).
- **Auth overrides:** Ensure AshAuthentication pages (sign-in, register, reset, magic link, confirm) are overridden so layout and components match the rest of the app (centered auth layout + same buttons/inputs/typography).

---

## 5. What Not to Do

- Do not use "SnapVault" anywhere; the app is **Lumina**.
- Do not leave any page with raw Tailwind grays/indigos; use the design tokens (base-content, accent, base-200, etc.).
- Do not mix layout patterns: auth pages are centered and minimal; authenticated app and admin use sidebar + main; public share uses minimal header only.

---

## 6. Implementation Order

1. Theme + fonts (app.css, root.html.heex).
2. Layouts: sidebar + main, then auth layout (centered), then public share (minimal).
3. Dashboard and main app pages (org, album, upload, share).
4. Auth pages (overrides + styling for sign-in, register, reset, magic link, confirm).
5. Admin (Backup, Orgs).
6. Join Live.
7. Share Live (public).
8. Core components and flash; final pass for consistency.

---

## Key Files

| Area         | Files                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------- |
| Theme/fonts  | `assets/css/app.css`, `lib/lumina_web/components/layouts/root.html.heex`                      |
| Layout       | `lib/lumina_web/components/layouts.ex`                                                        |
| Auth         | `lib/lumina_web/auth_overrides.ex`, AshAuthentication routes/templates                        |
| Main app     | `lib/lumina_web/live/dashboard_live.ex`, `org_live/*`, `album_live/*`, `photo_live/upload.ex` |
| Admin        | `lib/lumina_web/live/admin_live/backup.ex`, `admin_live/orgs.ex`                              |
| Join / Share | `lib/lumina_web/live/join_live.ex`, `share_live/show.ex`                                      |
| Components   | `lib/lumina_web/components/core_components.ex`                                                |
