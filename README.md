# Pactics Machine Tracking App

A shared, real-time web app for tracking every sewing machine at **Pactics Cambodia (Siem Reap)** — both in the **storage rack** and out on the **sewing lines**. Two people can use it at the same time, on phone or desktop, and every change is visible to the other instantly.

The whole app is a single `index.html` file. It runs on free hosting (Netlify) and a free cloud database (Supabase). No build step, no server to maintain.

---

## What it does

- **Storage rack tracking** — 45 physical slots (3 rows × 5 ports × 3 positions). Each slot has a printed QR label; scan or tap to assign a machine.
- **Sewing line tracking** — every line across all buildings, shown as an on-screen floor layout. Tap a position to assign a machine. No QR labels needed.
- **One machine, one place** — a machine is either on the rack *or* on a line, never both. Moving it to one automatically frees it from the other.
- **Full inventory** — every machine (stock + rental), searchable by code, fixed asset, serial, brand, or model. Add, edit, retire, and restore machines.
- **Find any machine instantly** — search a code and see exactly where it is: a rack slot, a line position, or free.
- **Live dashboard** — counts across the whole operation (deployed, on rack, on lines, unassigned, active, retired), plus per-building line usage.
- **CSV export** — download the current rack state or line state to open in Excel.
- **Real-time sync** — changes from one user appear on the other's screen within a second, with a note of who changed what and when.

---

## How it's built

| Part | Technology |
| --- | --- |
| App | One `index.html` file (HTML + CSS + JavaScript, no framework) |
| Database | Supabase (hosted PostgreSQL) |
| Login | Supabase Auth — one shared email + password |
| Hosting | Netlify (drag-and-drop deploy) |
| Real-time | Supabase Realtime subscriptions |

There is no build step. The app talks directly to Supabase from the browser using the Supabase JavaScript library.

---

## Project structure

The system was built up over several steps. The key files:

**App**

- `index.html` — the complete app. This is the only file you deploy.

**Database setup (SQL — run in the Supabase SQL Editor)**

Run these once, in order, the first time you set up the database:

1. `Pactics_Rack_Setup.sql` — creates the rack tables, the 45 slots, the machine inventory, and security rules.
2. `Pactics_Rack_Inventory_Migration.sql` — adds the columns needed for editing/retiring machines.
3. `Pactics_Rack_Inventory_Update_2026.sql` — applies the 2026 inventory cleanup and rental re-coding.
4. `Pactics_Sewing_Line_Setup.sql` — creates the line tables, all buildings/lines/slots, and the "one machine, one place" rules.
5. `Pactics_Sewing_Line_Expand_25.sql` — adds Line 18 and tops every line up to 25 slots.

**Later adjustments (run only if you need them)**

- `Pactics_Line_PPA04_to_35.sql` — expands Line PPA04 to 35 slots.

All SQL files are **idempotent** — safe to run more than once without creating duplicates or losing data. They only ever add; they never delete existing assignments.

**Reference documents**

- `Pactics_Sewing_Machine_Inventory.docx` — the machine list.
- `Pactics_Storage_Rack_Slot_Assignment.docx` — the rack slot reference.
- `Pactics_Rack_Labels.pdf` — printable QR labels for the rack slots.
- `Pactics_Rack_Tracker_Setup_Guide.pdf` — step-by-step deployment guide.

---

## The data model

**Rack**

- `machines` — every machine: code, type, brand, model, condition, fixed asset, serial, source (stock/rental), and whether it's retired.
- `slots` — the 45 rack positions (e.g. `A-1-1`).
- `assignments` — which machine is in which rack slot.
- `history` — a log of every change.

**Sewing lines**

- `buildings` — the buildings (Building 1, 2, 3, 4, PD).
- `lines` — the lines in each building (e.g. Line 6, PPA04, Welding).
- `line_slots` — the numbered positions on each line (e.g. `B1-7-03`).
- `line_assignments` — which machine is at which line position.

**The "one machine, one place" rule** is enforced by database triggers: assigning a machine to a line automatically removes it from the rack, and vice versa. This can't be bypassed from the app, so the data always stays consistent.

---

## Buildings and lines

| Building | Lines |
| --- | --- |
| Building 1 | 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, PPA01, PPA04 |
| Building 2 | Welding |
| Building 3 | 16, 17, 18, 19, 20, 21, 22 |
| Building 4 | 1, 2, 3, 4, 5, 23 |
| PD | PD |

Every line has 25 positions, except **PPA04** which has 35. Positions are shown on screen as two facing rows — odd numbers on top, even numbers below — so position 1 faces position 2, just like machines facing each other across a real line.

---

## Setup from scratch

If you ever need to rebuild the system on a new account, here's the outline.

**1. Database (Supabase)**

1. Create a free Supabase project.
2. Open the **SQL Editor** and run the five setup SQL files in the order listed above.
3. Go to **Authentication → Users → Add user**, create one shared user with an email and password, and tick **Auto Confirm Email** (this step matters — an unconfirmed user can't log in).
4. From **Project Settings → API**, copy the **Project URL** and the **publishable key**.

**2. App (configure)**

Open `index.html` in a text editor. Near the top of the script section, fill in the two values you copied:

```javascript
const SUPABASE_URL = "https://YOUR-PROJECT.supabase.co";
const SUPABASE_KEY = "sb_publishable_...";
```

Save the file.

**3. Hosting (Netlify)**

1. Make sure the file is named exactly `index.html`.
2. Go to Netlify and drag the file onto the deploy area (or put it inside a folder and drag the folder).
3. Open the published URL and sign in with the shared email and password.

> **Tip:** Windows sometimes saves the download as `index (1).html` or `index.html.html`. Netlify needs the exact name `index.html`, so rename it if needed — or drop it inside a folder, which avoids the problem.

---

## Daily use

- **Assign a machine to the rack** — Rack or Assign tab, pick a slot, enter the machine code (or fixed asset / serial).
- **Assign a machine to a line** — Lines tab, choose the building, tap a position, enter the machine.
- **Find a machine** — Search tab, type the code; it shows the exact location and jumps you there.
- **Manage machines** — Inventory tab to add, edit, retire, or restore. Each machine shows where it currently is.
- **See the big picture** — Data tab for live counts and per-building line usage, plus CSV export.

A machine on the rack or on a line can't be retired until it's removed from that location — this prevents losing track of a machine that's still in use.

---

## Updating the app

The app is one file, so updating is just replacing it:

1. Make the change to `index.html`.
2. Drag the new file onto Netlify.
3. Hard-refresh the page (Ctrl + Shift + R).

To test a change safely without disturbing people using the live site, deploy to a **second Netlify site** first. Both sites can point at the same database, so you can try the new version with real data before switching the main site over.

Changes to line sizes or new lines are done with a small SQL file in Supabase (like `Pactics_Line_PPA04_to_35.sql`); the app picks up the new structure automatically after a refresh — no redeploy needed.

---

## Notes

- **Free tiers.** Both Supabase and Netlify are on free plans, which are enough for this app's size and a small number of users.
- **Shared login.** Both users share one account, so the "changed by" note shows the same name for both. This was a deliberate choice to keep things simple and avoid email rate limits.
- **Internal use.** This is an internal tool for Pactics Cambodia (Siem Reap).
