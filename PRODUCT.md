# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users
Couples. Two people, each on their own iPhone, linked to each other. Each person keeps their own little tallies of everyday things (chocolates eaten, coffees, runs, kisses) and checks in on the other's. Usage is quick and frequent: open, tap a category, snap a photo, add a line, done. Then the partner gets a push and peeks.

## Product Purpose
Melita lets a couple count the small things they each do, together. Each person creates categories (name + emoji + cover photo) and logs entries (photo + short note). The partner sees everything in real time and is notified on every new entry or category. Success: logging takes seconds, and the numbers become a running, affectionate scoreboard between the two.

## Positioning
A two-player tally, not a solo habit tracker and not a shared photo album. The count is the point (a playful, teasing scoreboard between partners); the photo and note are the receipt that proves it. Everything is visible to exactly one other person.

## Operating Context
- Logging happens in the moment, one-handed, often with the camera: eating, at a café, after a run.
- Checking happens on a push notification: "Ana added a 🍫 to Chocolates".
- Two top-level views: mine and my partner's. Partner's side is read-only.
- Spanish (Latin American) UI copy; informal "tú" voice.

## Capabilities and Constraints
- SwiftUI, iOS 17+ deployment target, Firebase (Auth email/password, Firestore realtime, Storage, Cloud Functions, FCM).
- Pairing: one person generates a 6-character code valid 48 h; the other types it.
- Category: name (≤40 chars), optional single emoji, optional cover photo. Owner-only edit/delete.
- Entry: optional photo and/or note (≤500 chars). Counters: total, today, week, month.
- Settings: display name, unlink partner, notifications, sign out.
- Intended for App Store publication to other couples (onboarding must stand on its own; no in-jokes in product copy).
- Undecided: streaks, charts, comparing counts between partners, Sign in with Apple.

## Brand Commitments
- Name: **Melita**. It is an affectionate nickname and stays.
- Voice: warm, playful, informal Spanish, short sentences.

## Evidence on Hand
No real user photos, testimonials, or store assets yet. Previous app icon (pink→purple gradient heart with check) is discarded.

## Product Principles
1. Logging in under five seconds beats every other feature.
2. The number is the hero; the photo is the receipt.
3. Two players, one scoreboard: always make the partner's presence felt.
4. Teasing, never guilt: counts celebrate, they don't judge.
5. Native first: it should feel like an iPhone app a couple would trust with their private moments.
