# QA Test Checklist – Lumina

Lumina is a multi-organization photo sharing app. Use this checklist to manually verify core flows and access control. Run the app locally (e.g. `mix phx.server`) or against a staging environment.

**Suggested setup:**

- One **admin** account (can create orgs, access Admin Backup and Manage Organizations).
- One **regular user** account (can only join orgs via invite, then use orgs/albums/photos/share).
- Optional: Google OAuth configured for "Sign in with Google" tests.
- For backup tests: set `LUMINA_BACKUP_PASSWORD` in the environment.

---

## 1. Authentication

### Sign up (invite-only, OAuth only)

- [ ] Without invite: open `/sign-in`, sign in with Google; if new user, account is not created; error "You need an invitation to sign up" and redirect to sign-in.
- [ ] With invite: open `/join/:token` (valid token), redirect to sign-in with return_to; sign in with Google; account created and redirected to join page; redeem invite and join org.

### Sign in

- [ ] Sign in with Google (if configured); redirect to dashboard (or `return_to` if set).
- [ ] Admin: click "Admin sign in" on sign-in page; email/password form appears; sign in with correct admin credentials; redirect to dashboard.
- [ ] Admin: sign in with wrong password; error shown, stay on sign-in.

### Sign out

- [ ] Click Sign out; session cleared, redirect to sign-in or home.

### Password reset (if enabled)

- [ ] Request reset; receive email (or see in dev mailbox), use link and set new password; can sign in with new password.

### Protected routes

- [ ] While signed out, open `/` or `/orgs/new`; redirect to sign-in with appropriate message (and `return_to` where applicable).

---

## 2. Dashboard (authenticated)

### Admin

- [ ] Dashboard shows "Your Organizations" and "Create Organization" + "Manage Organizations".
- [ ] Search organizations by name; list filters correctly.
- [ ] Empty state: no orgs; message and link to create org or join org as appropriate.

### Regular user

- [ ] Dashboard shows "Join Organization" (no "Create Organization").
- [ ] Direct visit to `/orgs/new` redirects with error "Only administrators can create organizations".

---

## 3. Organizations

### Create organization (admin only)

- [ ] Go to Create Organization; submit name (and slug if required); org created, redirect to org page.
- [ ] Submit invalid data (e.g. duplicate slug or blank name); error shown, form retained.

### View organization

- [ ] Click org from dashboard; org page shows albums and "New Album" (or equivalent).
- [ ] Search albums by name (if implemented); results update.

### Admin – Manage Organizations (`/admin/orgs`)

- [ ] Admin: page loads; list of orgs; can create, edit, delete orgs.
- [ ] Non-admin: redirect with "Only administrators can access this page".
- [ ] Generate invite: choose org, role (owner/member), expiry; invite link/code shown; copy works.

---

## 4. Join organization (regular user)

### Via invite link

- [ ] Signed out: open `/join/:token`; redirect to sign-in with return_to to join.
- [ ] Signed in: open valid `/join/:token`; see org name and confirm join; after join, redirect or dashboard shows org.
- [ ] Invalid or expired token; "Invalid or expired invite" (or similar) shown.

### Via code

- [ ] Go to `/join`, enter valid invite code; join succeeds.
- [ ] Enter invalid code; error shown.

---

## 5. Albums

### Create album

- [ ] From org page, create album with name (and optional description); album created, redirect to album view.
- [ ] Submit without required name; validation error.

### Album view

- [ ] Album shows photos (or empty state); links to Upload and Share visible.
- [ ] Search/filter photos by name/tags (if present); results update.

### Album actions

- [ ] Open album menu; delete album (with confirmation if implemented); album removed, redirect or list updates.

---

## 6. Photo upload

### Happy path

- [ ] Upload 1–10 images (JPG, PNG, GIF, WebP); all accepted, thumbnails appear in album.
- [ ] Cancel an upload in progress; entry removed.

### Limits

- [ ] File > 10 MB; rejected or clear error.
- [ ] More than 10 files in one batch; rejected or only first 10 accepted.
- [ ] Unsupported type (e.g. PDF); rejected or clear message.

### Storage

- [ ] Upload that would exceed org storage (4 GB); error "Organization storage limit would be exceeded" (or equivalent).

---

## 7. Album share (create link)

### Create share link

- [ ] Set expiry (e.g. 1–365 days) and optional password; link created and displayed.
- [ ] Copy link; open in incognito/anonymous window; album loads (or password form if password set).

### Share page (public)

- [ ] Public link without password: album and photos visible without login.
- [ ] Public link with password: password form shown; correct password unlocks album; wrong password shows error.
- [ ] Expired link: "This link has expired" (or similar).
- [ ] Invalid token: "Invalid share link" (or similar).

---

## 8. Album view – photo actions

- [ ] Open photo in lightbox; navigate prev/next and close.
- [ ] Rename photo; name updates in list.
- [ ] Edit tags (if implemented); tags save and display.
- [ ] Delete photo (with confirmation if present); photo removed from album.

---

## 9. Admin backup

- [ ] Admin: open `/admin/backup`; password form shown.
  - [ ] Wrong password; error, no download.
  - [ ] Correct password (e.g. `LUMINA_BACKUP_PASSWORD`); backup download triggered (tar.gz with DB + uploads).
- [ ] Non-admin: access to backup page (if visible) still requires backup password; no privilege escalation.

---

## 10. Navigation and layout

- [ ] Sidebar/nav: correct links for role (Dashboard, Join/Create org, Admin links for admin only).
- [ ] Breadcrumbs or back links from org → album → upload/share work.
- [ ] Flash messages (success/error) appear and dismiss or persist as designed.
- [ ] Mobile/responsive: key flows (sign-in, dashboard, album view, share page) usable on small viewport.

---

## 11. Edge cases and security

- [ ] Access another org's URL (e.g. guessed slug) as non-member; 403 or redirect (no data leak).
- [ ] Share link URL with wrong token; friendly error, no stack trace in production.
- [ ] Session: after sign out, protected URLs redirect to sign-in.
