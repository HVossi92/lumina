# Album full-size image viewer with prev/next navigation

## Overview

Add a lightbox to the album show page so clicking a photo opens the original image full-size with previous/next navigation and keyboard support (Escape to close, arrows to navigate). State is server-driven on the same page; no new route.

---

## Thumbnail and original formats (updated)

- **Thumbnails** are now **AVIF**: stored as `priv/static/uploads/thumbnails/<uuid>.avif` (see `Lumina.Media.Thumbnail` `@thumbnail_ext ".avif"`).
- **Originals** keep the upload extension: `priv/static/uploads/originals/<uuid>.<ext>` (e.g. `.jpg`, `.png`).

The plan **does not hardcode extensions**. It uses the **Photo struct’s stored paths**:

- Grid thumbnails: `Path.basename(photo.thumbnail_path)` → e.g. `uuid.avif`.
- Lightbox image: use the **original** file. Prefer **`Lumina.Media.Thumbnail.original_url_from_path(photo.original_path)`** for the lightbox image URL (and `thumbnail_url_from_path` for grid if desired) so URLs stay correct for any path/format. Fallback: `~p"/uploads/originals/#{Path.basename(photo.original_path)}"`.

This keeps the implementation correct regardless of current or future thumbnail/original formats.

---

## Implementation summary

### 1. Album show LiveView ([lib/lumina_web/live/album_live/show.ex](lib/lumina_web/live/album_live/show.ex))

- **Assign:** `lightbox_index: nil` in mount; when set, it is the index into `@photos` for the current image.
- **Stable order:** Sort photos in mount (e.g. by `inserted_at`) so prev/next order is consistent.
- **Events:** `open_lightbox` (index), `close_lightbox`, `lightbox_prev`, `lightbox_next`, `lightbox_keydown` (Escape / ArrowLeft / ArrowRight).

### 2. Thumbnails open lightbox

- Iterate with index (e.g. `Enum.with_index(@photos)`). On the **image** (or wrapper), add `phx-click="open_lightbox"` and `phx-value-index={idx}`. Keep the existing Delete button and its `phx-click="delete_photo"` on the overlay.

### 3. Lightbox overlay

- When `@lightbox_index != nil`: fixed full-screen overlay (e.g. `fixed inset-0 z-50 bg-black/90`), show original image via `Thumbnail.original_url_from_path(photo.original_path)` or `~p"/uploads/originals/#{Path.basename(photo.original_path)}"`, with `max-h-screen max-w-screen object-contain`. Close button and backdrop `phx-click="close_lightbox"`. Prev/Next buttons sending `lightbox_prev` / `lightbox_next`; hide or disable at first/last.

### 4. Keyboard

- Colocated or external JS hook rendered only when lightbox is open: on keydown push `"lightbox_keydown"` with `%{"key" => event.key}`. Server handles Escape (close), ArrowLeft (prev), ArrowRight (next).

### 5. Accessibility

- Lightbox: `role="dialog"`, `aria-modal="true"`, `aria-label="Photo viewer"`. Buttons: `aria-label="Close"`, `"Previous photo"`, `"Next photo"`.

---

## Files to touch

- **[lib/lumina_web/live/album_live/show.ex](lib/lumina_web/live/album_live/show.ex):** Assigns, events, clickable thumbnails with index, lightbox overlay, optional colocated `.LightboxKeys` hook.
- **[assets/js/app.js](assets/js/app.js)** (optional): Register external `LightboxKeys` hook if not colocated.

No new routes or dependencies.
