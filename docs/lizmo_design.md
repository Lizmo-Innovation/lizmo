# Lizmo — Design System (design.md)

This is the reference for any screen, component, or UI work built for Lizmo. Follow these tokens and rules so every screen looks like it belongs to the same app, without re-deriving the visual language each time.

**Direction:** modern fintech — clean, trustworthy, mobile-first. Peso-green brand color, rounded cards, monospace numerals, tinted status chips. The one signature element is the **bed strip** (Section 5) — everything else stays quiet so that element reads clearly.

---

## 1. Color

| Token | Hex | Use |
|---|---|---|
| `color-peso-green` | `#0F6E56` | Primary brand color. CTAs, active nav states, positive/paid emphasis, headers on brand surfaces |
| `color-mint-tint` | `#E4F5EE` | Light background for "paid"/success chips and surfaces |
| `color-paper` | `#F7F8F6` | App background (screen bg, not card bg) |
| `color-ink` | `#16211D` | Primary text color |
| `color-coral` | `#E2542D` | Overdue / danger / rejected states |
| `color-coral-tint` | `#FCEAE4` | Background for overdue/danger chips |
| `color-amber` | `#B97A12` | Pending / awaiting-verification states |
| `color-amber-tint` | `#FBF0DC` | Background for pending chips |
| `color-card` | `#FFFFFF` | Card and surface background |
| `color-line` | `#E7EAE5` | Hairline dividers |
| `color-text-secondary` | `#6B7970` | Secondary/muted text (labels, metadata, timestamps) |
| `color-vacant` | `#E1E6E1` | Neutral fill for vacant/unoccupied states (bed strip segments, empty states) |

**Rules:**
- `color-peso-green` is the only brand accent. Don't introduce a second "primary" color — coral and amber are semantic (danger/pending), not decorative alternates.
- Status color mapping is fixed across the whole app: **green = paid/confirmed/active, amber = pending/awaiting verification, coral = overdue/rejected, gray (`color-vacant`) = vacant/inactive/neutral.** Never reassign these to other meanings.
- Text on a tint background always uses the matching saturated color (e.g., `color-coral` text on `color-coral-tint` background), never `color-ink` on a tinted chip.
- Backgrounds: screen background is always `color-paper`; anything elevated (cards, sheets, modals) is `color-card` on top of it. Don't put `color-card` directly on `color-card`.

---

## 2. Typography

Two type families, role-based, not decorative pairing:

| Role | Family | Weight(s) | Use |
|---|---|---|---|
| UI / headings / body | **Plus Jakarta Sans** | 400 (body), 500 (medium emphasis), 600 (labels/subheads), 800 (headings) | All interface text — headings, body copy, buttons, labels |
| Numeric | **IBM Plex Mono** | 500 (default), 600 (emphasized totals) | Peso amounts, dates, due-date figures, any tabular/ledger number |

**Type scale (Plus Jakarta Sans):**
| Style | Size | Weight | Use |
|---|---|---|---|
| Screen title | 24px | 800 | Top of screen, e.g. "Rent roll" |
| Section heading | 16px | 700 | Card group headers |
| Body | 16px | 400 | Standard reading text |
| Emphasis / row title | 15px | 600–700 | Tenant name, unit name, list-row primary text |
| Caption / metadata | 12–13px | 500 | Timestamps, "due Aug 5", helper text |
| Eyebrow / label | 11–12px | 600–700, uppercase, +1px tracking | Property name above a screen title, section labels |

**Numeric scale (IBM Plex Mono):**
| Style | Size | Weight | Use |
|---|---|---|---|
| Large stat | 20px | 600 | Dashboard stat cards |
| Row amount | 15–16px | 500–600 | Peso amounts in lists |
| Inline figure | 13–14px | 500 | Dates, smaller numeric labels |

**Rules:**
- Any peso amount, date, or due-day figure renders in IBM Plex Mono — never in Plus Jakarta Sans. This is what gives numbers their "ledger-accurate, scannable" feel.
- Never introduce a third font family. If something needs more visual weight, use a heavier Plus Jakarta Sans weight (800), not a new face.
- No decorative/script/serif fonts anywhere in the product UI.

---

## 3. Layout & Surfaces

- **Corner radius:** 16px for cards, 18–20px for larger containers (bottom sheets, primary action buttons), 20px+ for pill/chip shapes (fully rounded).
- **Card shadow:** flat, soft, minimal — `0 1px 3px rgba(0,0,0,0.05)` for resting cards. Never use heavy drop shadows, glows, or gradients.
- **Spacing:** screen horizontal padding 20–22px. Card internal padding 14–18px. Vertical gap between stacked cards: 10–12px.
- **Grid:** stat cards (dashboard summary numbers) sit two-up in a row with 10px gap. Don't go beyond 2 stat cards per row on mobile widths.
- **Buttons:** primary action is a full-width rounded button (16px radius) filled with `color-peso-green`, white text, 700 weight. One primary button per screen max — everything else is a secondary/ghost style or a text link.

---

## 4. Status Chips

Used for whole-unit leases and any single-status object (a payment, a maintenance request).

```
.chip {
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 20px; /* fully rounded */
}
```

| State | Background | Text |
|---|---|---|
| Paid / Confirmed / Active | `color-mint-tint` | `color-peso-green` |
| Overdue / Rejected | `color-coral-tint` | `color-coral` |
| Pending / Awaiting verification | `color-amber-tint` | `color-amber` |

Never use a stamp, badge-with-border, or icon-only indicator for status — always this tinted chip pattern. Consistency here is what lets a landlord scan a long list quickly.

---

## 5. Signature Element — The Bed Strip

This is Lizmo's one distinctive, non-generic visual — reserve boldness for this and keep everything else quiet.

**What it is:** on any **bedspace** unit card, render a horizontal segmented bar — one equal-width segment per bed in that unit — color-coded by that bed's current billing status (green/amber/coral/gray, per Section 1). Below the strip, a short legend summarizes counts (e.g., "2 paid · 1 overdue").

**When to use it:**
- Any card or list row representing a `Unit` where `rental_mode = BEDSPACE`.
- Do **not** use it for `WHOLE_UNIT` leases — those show a single status chip instead (Section 4), since there's nothing to segment. This distinction itself communicates the rental mode without a separate label.

**Spec:**
```
.bed-strip {
  display: flex;
  gap: 3px;
  height: 10px;
  border-radius: 6px;
  overflow: hidden;
}
.bed-seg { flex: 1; } /* one per bed, equal width regardless of bed count */
```
- Segment order should match a stable bed ordering (e.g., bed_label sort), not shuffle between renders.
- Strip always sits directly below the unit name/subtitle, above any legend text, inside the unit card.
- Legend uses small color dots + count, in `color-text-secondary` for the label text and the matching status color for each dot — never spell out individual tenant names in the legend itself (that's what tapping into the card is for).

**Why this is the signature:** it's derived directly from Lizmo's actual bedspace data model (Bed as a first-class entity — see the product spec), not decoration borrowed from a generic dashboard. No other rental app in this space visualizes shared-room occupancy this way.

---

## 6. Component Patterns

**Stat card** (dashboard summary numbers):
- `color-card` background, 16px radius, 14–16px padding, no border
- Large IBM Plex Mono number (20px/600) + small label beneath (11px/500, `color-text-secondary`)
- Used in rows of 2

**Unit/lease card:**
- `color-card`, 18px radius, 16–18px padding
- Top row: unit/tenant name (15px/700) + subtitle metadata (12px/500, `color-text-secondary`)
- If BEDSPACE: bed strip + legend (Section 5)
- If WHOLE_UNIT: amount (IBM Plex Mono) right-aligned + status chip (Section 4)

**List row (flat list, not card-wrapped)** — for things like notifications, documents:
- 14px vertical padding, `color-line` 1px bottom divider
- Primary text 14–15px/600, secondary text 12px/500 `color-text-secondary`, trailing content right-aligned

**Primary action button ("+ Record a payment" style):**
- Full width minus screen padding, `color-peso-green` fill, white text, 700 weight, 16px radius, 14–15px vertical padding
- Reserved for the single most important action on a screen (e.g., submit payment, post notice) — not used for secondary/tertiary actions

---

## 7. Do / Don't

| Do | Don't |
|---|---|
| Use IBM Plex Mono for every peso amount and date | Set a peso amount in Plus Jakarta Sans |
| Use the bed strip only for BEDSPACE units | Apply the bed strip to whole-unit cards, or use a stamp/badge instead of a chip |
| Keep one primary (filled, peso-green) button per screen | Stack multiple filled peso-green buttons on one screen |
| Use tinted chips for status | Invent new status colors outside the green/amber/coral/gray mapping |
| Keep cards on `color-paper` background | Nest a card directly on another card's same white |

---

*design.md v1 — companion to Lizmo_Product_Spec_v1.md and Lizmo_Tech_Spec_v1.md. Reference this file at the start of any Lizmo screen or component build.*
