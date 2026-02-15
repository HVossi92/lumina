# Per-org 4GB storage limit (Ash-idiomatic)

## Overview

Enforce a 4GB per-organization storage limit using Ash-idiomatic patterns: resource aggregate on Org for storage sum, a before_action change on Photo create for validation, and an on_mount hook to pass storage data to the layout for the visible indicator.

---

## 1. Storage aggregate on Org

- In [lib/lumina/media/org.ex](lib/lumina/media/org.ex): add `aggregates do sum :storage_used_bytes, :photos, :file_size do default 0 end end`.
- Define storage limit constant (e.g. `@storage_limit_bytes 4 * 1024 * 1024 * 1024`) in Org or a small `Lumina.Media.Storage` module.
- Load with `Ash.load!(org, :storage_used_bytes)`; access as `org.storage_used_bytes`.

## 2. Enforce limit on Photo create

- Add `change before_action(fn changeset, context -> ... end)` (or dedicated change module `Lumina.Media.Photo.Changes.ValidateStorageLimit`) to Photo’s create action.
- Use `context.tenant` as org_id; load Org with `storage_used_bytes`; if `current + file_size > limit`, `Ash.Changeset.add_error(changeset, ...)` with a clear message (e.g. "Organization storage limit (4 GB) would be exceeded").

## 3. Upload LiveView

- In [lib/lumina_web/live/photo_live/upload.ex](lib/lumina_web/live/photo_live/upload.ex): before `consume_uploaded_entries`, load org usage and sum batch sizes; if over limit, put flash error and do not process (reject entire batch).

## 4. Visible indicator

- New on_mount `:assign_org_storage` in [lib/lumina_web/live_user_auth.ex](lib/lumina_web/live_user_auth.ex) when `params["org_slug"]` present: load org with `storage_used_bytes`, assign `org_storage_used_bytes`, `org_storage_limit_bytes`, `current_org`.
- Layout [lib/lumina_web/components/layouts.ex](lib/lumina_web/components/layouts.ex): optional `org_storage_*` attrs; when present render storage bar (e.g. "X.X GB / 4 GB" with progress).
- Router: add on_mount to authenticated live_session.

---

## 5. Unit test coverage

Tests must cover: (1) displaying correct usage, (2) rejecting uploads when limit would be exceeded, (3) correct error messages shown to users, (4) uploads and deletions updating the displayed/aggregate limits.

### 5.1 Domain / resource tests

**File: [test/lumina/media/org_test.exs](test/lumina/media/org_test.exs)**

- **storage_used_bytes aggregate**
  - With no photos: org loaded with `storage_used_bytes` has `storage_used_bytes == 0` (or `nil` if not defaulted; then assert default in code or test loaded value).
  - With one photo with `file_size: 1000`: after loading org with `storage_used_bytes`, assert `org.storage_used_bytes == 1000`.
  - With multiple photos (e.g. 500, 1500): assert `org.storage_used_bytes == 2000`.
  - After deleting a photo: reload org with aggregate and assert sum decreased by that photo’s `file_size` (i.e. **deletions correctly update the aggregate**).

**File: [test/lumina/media/photo_test.exs](test/lumina/media/photo_test.exs)**

- **create rejects when limit would be exceeded**
  - Create photos up to just under 4GB (e.g. one photo with `file_size: 4 * 1024 * 1024 * 1024 - 100`).
  - Attempt to create one more photo with `file_size: 200` (total would exceed 4GB).
  - Assert `{:error, error}` and that the error message indicates the organization storage limit would be exceeded (e.g. message contains "4 GB" or "storage limit").
  - **Error message content**: assert the error shown to users is the same message used in the change (e.g. "Organization storage limit (4 GB) would be exceeded") so that **correct error messages** are verified.
- **create allows when at or under limit**
  - With current usage at 4GB - 1 byte, creating a photo with `file_size: 1` succeeds.

### 5.2 LiveView tests

**File: [test/lumina_web/live/photo_live_test.exs](test/lumina_web/live/photo_live_test.exs)** (upload flow)

- **not allowing new uploads when limit would be exceeded**
  - Set up org with usage at or near 4GB (e.g. via fixtures or by creating photos with large `file_size`).
  - Log in, go to upload page for that org/album.
  - Simulate or trigger upload that would exceed limit (e.g. render with uploads that sum over remaining space, or trigger "save" with mock entries if test setup allows).
  - Assert user sees an error (flash or inline) and upload does not complete (e.g. no redirect to album, or flash contains the storage limit message).
- **displaying correct error message**
  - Same or dedicated test: assert the visible error text matches the intended user-facing message (e.g. "Organization storage limit (4 GB) would be exceeded" or "storage limit").

**File: new or existing LiveView test for org-scoped pages (e.g. [test/lumina_web/live/org_live_test.exs](test/lumina_web/live/org_live_test.exs) or album/upload)**

- **displaying correct usage**
  - With an org that has known total `file_size` (e.g. one photo with `file_size: 2_000_000`), visit an org-scoped page (org show or album show) so the layout runs with `assign_org_storage`.
  - Assert the page (or layout) shows the expected usage (e.g. "~1.9 MB" or "2 MB" depending on formatting) and the limit "4 GB" (or equivalent).
  - Optionally: add a second test with zero photos and assert "0 B" or "0 MB" and "4 GB".

**File: [test/lumina_web/live/album_live_test.exs](test/lumina_web/live/album_live_test.exs)** (if album show has storage bar)

- **uploads and deletions correctly update the limits (UI)**
  - After uploading a photo (or using a fixture to add one), reload or re-render the album/org page and assert the displayed usage increased by that photo’s size (or by the uploaded file size).
  - After deleting a photo (via UI or in test by destroying the photo and re-mounting), assert the displayed usage decreased accordingly.

### 5.3 Test helpers / fixtures

- In [test/support/fixtures.ex](test/support/fixtures.ex): `photo_fixture` already accepts `file_size`; use it to build orgs at specific usage levels (e.g. `file_size: 4 * 1024 * 1024 * 1024 - 1`).
- For "at limit" tests, consider a small helper that creates an org and enough photos (or one large `file_size` photo) to reach a target byte total, to avoid repeating setup.

### 5.4 Summary checklist

- [ ] Org aggregate: `storage_used_bytes` is 0 with no photos, correct sum with one/many photos, and decreases after a photo is deleted.
- [ ] Photo create: rejected when adding the new photo would exceed 4GB; error message contains the intended storage-limit text; create succeeds when at or under limit.
- [ ] Upload LiveView: when limit would be exceeded, user sees error and upload does not complete; error message matches intended text.
- [ ] Org-scoped layout: displayed usage and limit (e.g. "X.X GB / 4 GB") match actual aggregate and constant.
- [ ] After upload and after delete, the displayed storage usage updates correctly (tests that both uploads and deletions update the limits).

---

## Files to add or modify (implementation)

| File                                                                                 | Change                                                          |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| [lib/lumina/media/org.ex](lib/lumina/media/org.ex)                                   | Aggregates block; `@storage_limit_bytes`                        |
| [lib/lumina/media/photo.ex](lib/lumina/media/photo.ex)                               | `change before_action(...)` or `ValidateStorageLimit` on create |
| [lib/lumina_web/live_user_auth.ex](lib/lumina_web/live_user_auth.ex)                 | `on_mount(:assign_org_storage, ...)`                            |
| [lib/lumina_web/components/layouts.ex](lib/lumina_web/components/layouts.ex)         | Storage attrs and storage bar in layout                         |
| [lib/lumina_web/router.ex](lib/lumina_web/router.ex)                                 | Add on_mount                                                    |
| [lib/lumina_web/live/photo_live/upload.ex](lib/lumina_web/live/photo_live/upload.ex) | Pre-check batch vs limit; flash on exceed                       |

## Files to add or modify (tests)

| File                                                                                                  | Change                                                                                          |
| ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [test/lumina/media/org_test.exs](test/lumina/media/org_test.exs)                                      | Describe "storage_used_bytes": no photos, one/many photos, after delete                         |
| [test/lumina/media/photo_test.exs](test/lumina/media/photo_test.exs)                                  | Describe "storage limit": create rejected over limit (with message), create allowed under limit |
| [test/lumina_web/live/photo_live_test.exs](test/lumina_web/live/photo_live_test.exs)                  | Upload rejected when over limit; error message visible                                          |
| [test/lumina_web/live/org_live_test.exs](test/lumina_web/live/org_live_test.exs) or album/upload test | Displayed usage and limit correct; usage updates after upload and after delete                  |

Optional: dedicated change module `Lumina.Media.Photo.Changes.ValidateStorageLimit` and unit test for that change in isolation if desired.
