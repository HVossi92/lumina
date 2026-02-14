# Fix org form name/slug clearing and forms audit (idiomatic)

## Overview

Fix the org creation form so name and slug no longer clear each other by binding inputs to form state, merging params on validate, and auto-generating the slug. Use **Tidewave MCP** during implementation for Ash/Phoenix/LiveView docs and project eval. Follow **idiomatic Elixir, Ash, Phoenix, and LiveView** practices.

---

## Tools and practices

### Tidewave MCP (use during implementation)

- **`mcp_tidewave_get_docs`** – Look up `Phoenix.Component.to_form/2`, `Ash.Changeset`, `Ash.Resource.Change`, `Phoenix.HTML.Form` when implementing.
- **`mcp_tidewave_get_ash_resources`** – Confirm `Lumina.Media.Org` actions and attributes.
- **`mcp_tidewave_get_source_location`** – Find `Ash.Changeset.change_attribute/3`, `force_change_attribute/3` when writing the slug change.
- **`mcp_tidewave_project_eval`** – Test slugify logic and form param merging in project context (e.g. `Phoenix.HTML.Form.to_form(%{"name" => "A"}, as: "org").params`).
- **`mcp_tidewave_search_package_docs`** – Search Ash for “change”, “before_action”; Phoenix LiveView for “form phx-change validate”.

### Idiomatic patterns

- **Ash**: Keep business logic in the resource layer. Use an `Ash.Resource.Change` module to generate slug from name when slug is blank; use `Ash.Changeset.change_attribute/3` or `force_change_attribute/3` inside the change. Add the change to the create action so slug is always set before persist.
- **Phoenix/LiveView**: Use the project’s `<.input>` from `core_components.ex` with `field={@form[:name]}` so inputs are bound to form state. On validate, merge current form params with incoming params (e.g. from `socket.assigns.form.params`) so no field is dropped when the client sends partial data.
- **Elixir**: Implement slugify as a pure function in a dedicated module (e.g. `LuminaWeb.Helpers` or `Lumina.Slugs`) so it’s testable and reusable; no side effects.

---

## Root cause

In `lib/lumina_web/live/org_live/new.ex`, the form uses **raw `<input>` elements without binding `value` to the form**. On each `phx-change="validate"` the server does `assign(socket, form: to_form(org_params, as: "org"))`. The client can send only the field that was edited (or the other field empty), so the other field is lost. The template does not output `value=` for inputs, so re-renders can show empty values. Result: typing in name clears slug, typing in slug clears name.

---

## 1. Slug generation (Ash + Elixir)

### Slugify helper (Elixir)

- Add a small **pure function** `slugify/1` in a dedicated module, e.g. `Lumina.Slugs` or `LuminaWeb.Helpers`: lowercase, replace non-`[a-z0-9\s-]` with `""`, replace runs of spaces with `"-"`, trim leading/trailing `"-"`. Keep it in `lib/` so it’s reusable and easy to unit test.

### Ash change for auto-slug (idiomatic Ash)

- Create an **`Ash.Resource.Change`** module (e.g. `Lumina.Media.Org.GenerateSlugFromName`) that:
  - In `change/3`, reads the current name and slug from the changeset (`Ash.Changeset.get_attribute/2` or params).
  - If slug is blank or nil, sets `slug` to `YourApp.Slugs.slugify(name)` using `Ash.Changeset.change_attribute/3` (or `force_change_attribute/3` if the attribute is not in the action’s accept list).
- Add this change to `Lumina.Media.Org` create action: `change Lumina.Media.Org.GenerateSlugFromName`.
- Use **Tidewave**: `mcp_tidewave_get_docs` for `Ash.Resource.Change` and `Ash.Changeset.change_attribute/3`; `mcp_tidewave_get_source_location` for the exact change API if needed.

This keeps “slug from name” as **resource-level business logic** and allows the LiveView to send only `name` (slug optional) or both.

---

## 2. Org form (LiveView) – fix clearing and wire auto-slug

### Bind inputs to form state (Phoenix/LiveView)

- Replace raw `<input>` elements with the project’s **`<.input>`** from [lib/lumina_web/components/core_components.ex](lib/lumina_web/components/core_components.ex): e.g. `<.input field={@form[:name]} type="text" label="Name" ... />` and `<.input field={@form[:slug]} type="text" label="Slug (URL-friendly name)" ... />`. Preserve `pattern="[a-z0-9-]+"` and helper text for slug. Per project rules, use the imported `<.input>` and avoid overriding default input classes unless necessary.
- This ensures both fields display and submit from the form state so re-renders don’t clear the other field.

### Merge params on validate (LiveView)

- In `handle_event("validate", %{"org" => org_params}, socket)`:
  - Current params: from `socket.assigns.form.params` (form built with `to_form(params, as: "org")` so `form.params` is the map).
  - Merged: `Map.merge(current_params, org_params)` so incoming keys override but we keep the other field.
  - Assign: `to_form(merged, as: "org")`.
- Optionally track `slug_manually_edited` in assigns: set to `true` when the user edits slug and it differs from `Slugs.slugify(name)`; when `false`, in validate set `merged["slug"]` to `Slugs.slugify(merged["name"] || "")` so the UI shows the auto-slug. If you prefer simplicity, rely on the Ash change and only merge params; slug can still be optional in the form and generated on create.

### Save path

- On submit, pass `name` and `slug` (or only `name` if slug is optional). If slug is blank, the Ash change will set it from name. Ensure `Org.create` is called with the merged/generated slug when the LiveView supplies it (no change needed if the change always runs on create).

### Tests

- [test/lumina_web/live/org_live_test.exs](test/lumina_web/live/org_live_test.exs): Keep “creates new organization” with both name and slug. Add a test that submitting only name (slug blank) still creates an org and redirects to the slug generated from name. Use `mcp_tidewave_project_eval` if helpful to assert on slug format.

---

## 3. Forms audit – same pattern (phx-change + multiple fields)

### Album create – [lib/lumina_web/live/album_live/new.ex](lib/lumina_web/live/album_live/new.ex)

- Same pattern: raw `<input>` and `<textarea>` with no `value` binding and `phx-change="validate"`; name and description can clear each other.
- **Fix**: Use `<.input field={@form[:name]} ... />` and `<.input field={@form[:description]} type="textarea" ... />` (or equivalent from core_components). In validate, merge `socket.assigns.form.params` with `album_params` before `to_form(merged, as: "album")`.

### Album share – [lib/lumina_web/live/album_live/share.ex](lib/lumina_web/live/album_live/share.ex)

- No `phx-change`, only `phx-submit`. No clearing issue. Optional: use form-backed inputs and a single `handle_event("create_link", %{"share" => params}, ...)` for consistency.

### Admin backup – [lib/lumina_web/live/admin_live/backup.ex](lib/lumina_web/live/admin_live/backup.ex)

- Single password field, submit-only. No change required.

---

## 4. Implementation order

1. Add **slugify module** (e.g. `Lumina.Slugs.slugify/1`) and unit test.
2. Add **Ash change** `Lumina.Media.Org.GenerateSlugFromName` and attach to Org create action; verify with `mcp_tidewave_project_eval` or a quick create in IEx.
3. **OrgLive.New**: Merge params on validate, switch to `<.input field={@form[:name]}>` and `<.input field={@form[:slug]}>`, ensure submit passes name/slug (slug optional if change fills it).
4. **AlbumLive.New**: Merge params on validate, switch to `<.input field={@form[:name]}>` and `<.input field={@form[:description]} type="textarea">`.
5. Run **`mix precommit`** and fix any issues; add/update org test for “name-only” create.

---

## Summary

| Form         | File                 | Issue                      | Action                                                                              |
| ------------ | -------------------- | -------------------------- | ----------------------------------------------------------------------------------- |
| Org new      | org_live/new.ex      | Name/slug clear each other | Bind inputs (`<.input field={@form[...]}>`), merge on validate, Ash change for slug |
| Album new    | album_live/new.ex    | Name/description can clear | Bind inputs, merge on validate                                                      |
| Album share  | album_live/share.ex  | None                       | Optional form consistency                                                           |
| Admin backup | admin_live/backup.ex | None                       | No change                                                                           |
