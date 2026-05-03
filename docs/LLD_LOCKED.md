# Pause — Low-Level Design (LOCKED)

> **This document is the single source of truth for the Pause app.**
> Do not modify. Version: 1.0 — Full LLD locked.

---

## Project Overview

| Attribute | Value |
|---|---|
| App name | Pause |
| Platform | Flutter — iOS primary, Android secondary |
| Architecture | Offline-first, local SQLite via Drift, Riverpod state |
| AI provider | Gemini Flash (primary) · Regex fallback (offline) |
| Design system | iOS Cupertino · Deep navy dark · Muted gold accent |
| Backend | None for MVP — LocalEventRepository only |

---

## Working Methodology

Layer order is **strict** — later layers import from earlier ones.

| Step | Action |
|---|---|
| 1 | Read the layer section fully |
| 2 | Q&A with Claude before implementing |
| 3 | Claude writes files |
| 4 | Run: `flutter analyze` |
| 5 | Paste any errors back for fixing |
| 6 | Confirm layer ✓, move to next |

---

## LAYER 0 — Design System Tokens

**File:** `lib/core/theme/app_theme.dart`
No widgets — pure tokens only.

### Color Tokens

| Token | Hex | Usage |
|---|---|---|
| backgroundTop | #0A0F1E | App gradient top |
| backgroundMid | #0C1224 | App gradient middle |
| backgroundBot | #05070F | App gradient bottom |
| surfaceL1 | #111827 | Cards, list rows |
| surfaceL2 | #151C2E | Chips, input fields |
| surfaceL3 | #1A2238 | Tags, tooltips |
| glassFill | rgba(255,255,255,0.04) | Mic, confirm card, hero stats |
| glassBorder | rgba(255,255,255,0.08) | Glass surface border |
| surfaceBorder | rgba(255,255,255,0.06) | Card borders |
| goldPrimary | #C6A969 | Numbers, mic glow, CTAs |
| goldHighlight | #E6C98A | Listening state, active gold |
| goldGlow | rgba(198,169,105,0.25) | Mic ring ambient glow |
| semanticExpense | #FF6B6B | Expense type, negative amounts |
| semanticSaved | #3FB8A6 | Saved type, positive amounts |
| textPrimary | #FFFFFF | Headlines, amounts |
| textSecondary | #A0A6B8 | Labels, descriptions |
| textTertiary | #4A5568 | Timestamps, hints, placeholders |

### Typography Scale

| Token | Size | Weight | Letter spacing | Usage |
|---|---|---|---|---|
| display | 34px | 700 | -0.03em | Hero amounts |
| title | 22px | 600 | -0.02em | Month header |
| headline | 17px | 600 | -0.01em | Card note, screen titles |
| body | 15px | 400 | 0 | Descriptions |
| caption | 12px | 500 | +0.02em | Timestamps |
| label | 10px | 600 | +0.10em | Category badges (all caps) |

### Spacing — 8pt Grid

| Token | Value | Usage |
|---|---|---|
| sp1 | 4px | Icon gap, tight inline pairs |
| sp2 | 8px | Chip padding, inline gap |
| sp3 | 12px | Card inner row gap |
| sp4 | 16px | Card horizontal padding |
| sp5 | 20px | Card vertical padding |
| sp6 | 24px | Section gap |
| sp8 | 32px | Screen horizontal padding |
| sp12 | 48px | Major section spacing |

### Motion

| Token | Duration | Curve | Usage |
|---|---|---|---|
| cardFloat | 240ms | easeOut | Cards sliding into view |
| sheetRise | 320ms | spring(0.4,0,0.2,1) | Confirmation sheet rising |
| swipeSnap | 280ms | spring bounce | Card snapping back |
| swipeDismiss | 220ms | easeIn | Card flying off screen |
| numberCount | 600ms | easeOut | Amount count-up animation |
| screenNav | 380ms | iOS default | CupertinoPageRoute transition |
| micBreathe | 4000ms loop | ease-in-out | Idle glow ring |
| micPulse | 800ms loop | ease-in-out | Listening ring pulse |

---

## LAYER 1 — Data Model & Enums

**Files:**
- `lib/core/models/enums.dart`
- `lib/core/models/financial_event.dart`
- `lib/core/models/parse_result.dart`

Rules: freezed-style immutability with `copyWith`. No external packages. All enums have `displayName` getter. `FinancialEvent` equality by `id` only.

### Enums

| Enum | Values |
|---|---|
| EventType | expense, saved |
| Category | food, travel, shopping, bills, entertainment, misc |
| PaymentMethod | upi, card, cash, netbanking, other |
| InputSource | voice, text |
| ReflectionState | worthIt, mehh, notWorthIt |
| ParseSource | ai, regex, manual |

### FinancialEvent

```dart
class FinancialEvent {
  final String id;              // UUID v4
  final EventType type;
  final double amount;          // always positive
  final String currency;        // "INR" default
  final Category category;
  final PaymentMethod? paymentMethod;
  final String? note;
  final InputSource source;
  final double? confidence;
  final String? rawInput;       // null once confirmed/edited
  final ReflectionState? reflection;  // expense only
  final DateTime? reflectedAt;
  final DateTime createdAt;     // UTC
  final DateTime? editedAt;
}
```

- `rawInput` is null once: confidence >= 0.8 AND user confirmed, OR user edited any field.
- `reflection` only valid on `EventType.expense`.
- `amount` always positive — type carries semantic direction.

### ParseResult

```dart
class ParseResult {
  final EventType type;
  final double? amount;
  final String currency;
  final Category category;
  final PaymentMethod? paymentMethod;
  final String? note;
  final double? confidence;
  final ParseSource source;
}
// Candidate only — becomes FinancialEvent after user confirms.
```

---

## LAYER 2 — Database Schema & Repository

**Files:**
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart` (generated)
- `lib/core/repository/event_repository.dart`
- `lib/core/repository/local_event_repository.dart`

### Drift Table — financial_events

| Column | Drift type | Nullable |
|---|---|---|
| id | TextColumn | No — primary key |
| type | TextColumn (enum) | No |
| amount | RealColumn | No |
| currency | TextColumn | No — default INR |
| category | TextColumn (enum) | No |
| paymentMethod | TextColumn (enum) | Yes |
| note | TextColumn | Yes |
| source | TextColumn (enum) | No |
| confidence | RealColumn | Yes |
| rawInput | TextColumn | Yes |
| reflection | TextColumn (enum) | Yes |
| reflectedAt | DateTimeColumn | Yes |
| createdAt | DateTimeColumn | No |
| editedAt | DateTimeColumn | Yes |

### Indexes

| Index | Columns | Purpose |
|---|---|---|
| events_created_at | created_at | Timeline queries |
| events_type_created_at | type, created_at | Insights by type + period |

### EventRepository Interface

```dart
abstract class EventRepository {
  Future<void> save(FinancialEvent event);
  Future<void> update(FinancialEvent event);
  Future<void> delete(String id);
  Future<List<FinancialEvent>> getAll();
  Future<List<FinancialEvent>> getByDateRange(DateTime from, DateTime to);
  Future<List<FinancialEvent>> getByType(EventType type);
  Future<List<FinancialEvent>> getByCategory(Category category);
  Future<FinancialEvent?> getById(String id);
  Future<List<FinancialEvent>> getPendingReview(); // rawInput != null
  Future<double> getTotalByType(EventType type, DateTime from, DateTime to);
  Future<Map<Category, double>> getCategoryBreakdown(EventType type, DateTime from, DateTime to);
}
```

**Rule:** UI and providers import `EventRepository` only — never `LocalEventRepository` directly.

---

## LAYER 3 — AI Parsing Layer

**Files:**
- `lib/core/parsing/rule_based_parser.dart`
- `lib/core/parsing/ai_parser_service.dart`
- `lib/core/parsing/parse_orchestrator.dart`

- AI: Gemini Flash via HTTP POST, 5s timeout, 1 retry on malformed JSON.
- API key: `String.fromEnvironment("GEMINI_API_KEY")`
- Always returns `ParseResult` — never throws to caller.

### System Prompt (verbatim)

```
You are a financial event parser for an Indian expense tracking app.
Extract structured data from natural language descriptions.
Return ONLY raw JSON. No markdown fences. No explanation.

Schema:
{
  "type": "expense" | "saved",
  "amount": number,
  "currency": "INR",
  "category": "food"|"travel"|"shopping"|"bills"|"entertainment"|"misc",
  "paymentMethod": "upi"|"card"|"cash"|"netbanking"|"other"|null,
  "note": string,
  "confidence": number
}

Rules:
- "saved" = money intentionally NOT spent
- note: 3-5 word clean summary, never include amount
- paymentMethod: detect from context or null
- confidence: 0.9 clear, 0.6 uncertain, 0.4 guessing
- Default currency INR
```

### Orchestrator Flow

| Tier | Condition | Result | rawInput |
|---|---|---|---|
| 1 — AI | Online, valid JSON | ParseResult(source: ai) | Keep if confidence < 0.8 |
| 2 — Regex | AI timeout / offline / bad JSON | ParseResult(source: regex) | Always kept |
| 3 — Manual | Regex finds no amount | ParseResult(source: manual, all null) | Always kept |

---

## LAYER 4 — Input Layer

**Files:**
- `lib/core/input/input_result.dart`
- `lib/core/input/voice_input_service.dart`
- `lib/core/input/text_input_service.dart`

- Both produce `InputResult { rawText: String, source: InputSource }`
- `VoiceState` enum: idle, listening, processing, result, error
- Silence timeout: 3s
- Hold mode / Tap-lock mode: if hold < 2s on release → hold mode; if released after 2s → tap-lock
- Never throw to caller — emit error state

### Voice State Machine

| From | Trigger | To | Side effect |
|---|---|---|---|
| idle | User presses mic | listening | Haptic medium, start STT |
| listening | Release (hold <2s) | processing | Haptic light |
| listening | Silence 3s | processing | Haptic light |
| listening | Second tap (tap-lock) | processing | Haptic light |
| listening | Cancel | idle | Stop STT, clear transcript |
| processing | Parse succeeds | result | Haptic success |
| processing | Parse fails all tiers | result | Empty ParseResult, manual mode |
| processing | STT fails | error | Haptic error |
| result | Confirm | idle | Event saved |
| result | Discard | idle | Nothing saved |
| error | Retry | listening | Restart STT |
| error | Dismiss | idle | — |

---

## LAYER 5 — Riverpod Providers

**Files:**
- `lib/core/providers/database_provider.dart`
- `lib/core/providers/repository_provider.dart`
- `lib/core/providers/home_stats_provider.dart`
- `lib/core/providers/timeline_provider.dart`
- `lib/core/providers/detail_stats_provider.dart`
- `lib/core/providers/filter_provider.dart`
- `lib/core/providers/input_overlay_provider.dart`

- Use `@riverpod` annotation + build_runner generation
- `AppDatabase` and `EventRepository` are singletons via Provider
- `HomeStatsProvider`: AsyncNotifier, current month range — **never watches FilterProvider**
- `TimelineProvider`: AsyncNotifier, watches FilterProvider, paginated 50/page
- `DetailStatsProvider`: AsyncNotifier, watches FilterProvider
- On every write: invalidate homeStats, timeline, detailStats

### FilterState

```dart
class FilterState {
  final DateRange dateRange;       // default: current month
  final Category? category;
  final PaymentMethod? paymentMethod;
  final EventType? type;
}
class DateRange {
  final DateTime from;
  final DateTime to;
  static DateRange currentMonth();
}
```

### InputOverlayState

```dart
class InputOverlayState {
  final bool isVisible;
  final VoiceState voiceState;
  final String liveTranscript;
  final ParseResult? parseResult;
  final ParseResult? editedResult;  // user edits applied on top
}
// editedResult starts as copy of parseResult.
// On confirm: save editedResult, null rawInput if confidence>=0.8 OR any field edited.
```

---

## LAYER 6 — Home Screen UI

**Files:**
- `lib/features/home/home_screen.dart`
- `lib/features/home/widgets/hero_stat_card.dart`
- `lib/features/home/widgets/recent_transaction_row.dart`
- `lib/features/home/widgets/mic_button.dart`

- `CupertinoPageScaffold` — ZERO Material widgets
- Background: vertical LinearGradient #0A0F1E → #0C1224 → #05070F
- Layout: Month header → HeroStatCards (2 side-by-side) → Recent (last 5) → Spacer → MicButton (bottom centre) + pencil icon left
- MicButton floats above content (not in nav bar)
- HeroStatCard: glass surface, blur 12px
- Pencil icon: expands text field upward, mic shrinks

### MicButton States

| State | Ring 1 | Ring 2 | Icon | Shadow | Animation |
|---|---|---|---|---|---|
| idle | gold 20% | gold 8% | #C6A969 | gold glow 8px | 4s breathe |
| listening | gold 50% | gold 25% | #E6C98A | gold glow 20px | 0.8s pulse |
| processing | none | none | #C6A969 | gold glow 12px | arc spinner |
| error | red 40% | none | #FF6B6B | red glow 8px | shake |

---

## LAYER 7 — Input Overlay & Confirmation Card

**Files:**
- `lib/features/input/input_overlay.dart`
- `lib/features/input/confirmation_card.dart`
- `lib/features/input/widgets/swipe_card.dart`
- `lib/features/input/widgets/editable_field_row.dart`

- Full-screen bottom sheet (`showCupertinoModalPopup`)
- Background blurs to 8px when visible
- Swipe right = confirm (green overlay), swipe left/down = discard (red overlay)
- Threshold feedback: haptic at 50%, spring snap-back if released before threshold
- Backdrop tap: snap back (NOT dismiss)
- Any field tap → CupertinoTextField inline, disables swipe until keyboard done
- Warning strip if confidence < 0.8 or source != ai: shows rawInput in gold tint

### On Confirm

- Build `FinancialEvent` from `editedResult`
- Set `rawInput = null` if confidence >= 0.8 OR any field was edited
- Call `repository.save(event)`
- Providers auto-invalidated

---

## LAYER 8 — Detail View & Insights

**Files:**
- `lib/features/detail/detail_screen.dart`
- `lib/features/detail/widgets/filter_bar.dart`
- `lib/features/detail/widgets/dual_pie_charts.dart`
- `lib/features/detail/widgets/transaction_list.dart`
- `lib/features/detail/widgets/transaction_detail_card.dart`
- `lib/features/detail/widgets/reflection_picker.dart`

- FilterBar: horizontal scroll chips, active = gold border
- Aggregate row from DetailStatsProvider
- DualPieCharts: fl_chart PieChart, category colors deterministic by enum index
- TransactionList: paginated 50/page, load-more on scroll
- TransactionDetailCard: reflection buttons (expense only), edit button
- Month-end banner: last 3 days, getPendingReview().length > 0

### Category Color Mapping

| Category | Color | Hex |
|---|---|---|
| food | Warm amber | #E6A838 |
| travel | Sky blue | #4A90D9 |
| shopping | Soft purple | #9B7FD4 |
| bills | Coral | #E07060 |
| entertainment | Teal | #3FB8A6 |
| misc | Muted grey | #6B7280 |

---

## LAYER 9 — Wiring & Navigation

**Files:** `lib/main.dart`, `lib/app.dart`, `lib/core/di/providers.dart`

- `ProviderScope` wraps entire app
- `CupertinoApp` — NOT `MaterialApp`
- `CupertinoPageRoute` for all navigation
- `AppDatabase` initialized once in `main()`, passed to ProviderScope overrides
- Mic permission requested on first launch (not first tap)
- Denied permission: `CupertinoAlertDialog` + mic button disabled state

---

## Appendix A — Design Rules (NEVER VIOLATE)

| Rule | Requirement |
|---|---|
| Widget system | Cupertino ONLY. Zero Material. No Scaffold, SnackBar, Dialog. |
| Glass | ONLY on: mic button, confirmation card, hero stat cards. |
| Blur depth | 10–14px only. Never exceed 14px. |
| Gold | Numbers, mic glow, active chips, primary actions ONLY. Never as background fill. |
| Animation | Transform and opacity only. Never animate color directly. |
| Semantic colors | Expense = #FF6B6B always. Saved = #3FB8A6 always. Never swap. |
| Text weights | 400/500/600/700 only. |
| Border radius | Min 10px on cards. 20px for sheets/overlays. |
| Haptics | Every mic state transition must have correct haptic. |
| Reflection | Only on EventType.expense. Never on saved. |
| rawInput rule | Null if confidence >= 0.8 AND confirmed. Null if any field edited. |
| Repository rule | UI imports EventRepository only. Never LocalEventRepository. |
| Invalidation | All three providers invalidated on every write. |
| Error messages | Never show raw exceptions. Always human-readable with fallback. |

---

## Appendix B — File Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/app_theme.dart                  ← Layer 0
│   ├── models/
│   │   ├── enums.dart                        ← Layer 1
│   │   ├── financial_event.dart              ← Layer 1
│   │   └── parse_result.dart                 ← Layer 1
│   ├── database/
│   │   ├── app_database.dart                 ← Layer 2
│   │   └── app_database.g.dart               ← Layer 2 (generated)
│   ├── repository/
│   │   ├── event_repository.dart             ← Layer 2
│   │   └── local_event_repository.dart       ← Layer 2
│   ├── parsing/
│   │   ├── rule_based_parser.dart            ← Layer 3
│   │   ├── ai_parser_service.dart            ← Layer 3
│   │   └── parse_orchestrator.dart           ← Layer 3
│   ├── input/
│   │   ├── input_result.dart                 ← Layer 4
│   │   ├── voice_input_service.dart          ← Layer 4
│   │   └── text_input_service.dart           ← Layer 4
│   └── providers/
│       ├── database_provider.dart            ← Layer 5
│       ├── repository_provider.dart          ← Layer 5
│       ├── home_stats_provider.dart          ← Layer 5
│       ├── timeline_provider.dart            ← Layer 5
│       ├── detail_stats_provider.dart        ← Layer 5
│       ├── filter_provider.dart              ← Layer 5
│       └── input_overlay_provider.dart       ← Layer 5
└── features/
    ├── home/
    │   ├── home_screen.dart                  ← Layer 6
    │   └── widgets/
    │       ├── hero_stat_card.dart           ← Layer 6
    │       ├── recent_transaction_row.dart   ← Layer 6
    │       └── mic_button.dart               ← Layer 6
    ├── input/
    │   ├── input_overlay.dart                ← Layer 7
    │   ├── confirmation_card.dart            ← Layer 7
    │   └── widgets/
    │       ├── swipe_card.dart               ← Layer 7
    │       └── editable_field_row.dart       ← Layer 7
    └── detail/
        ├── detail_screen.dart                ← Layer 8
        └── widgets/
            ├── filter_bar.dart               ← Layer 8
            ├── dual_pie_charts.dart          ← Layer 8
            ├── transaction_list.dart         ← Layer 8
            ├── transaction_detail_card.dart  ← Layer 8
            └── reflection_picker.dart        ← Layer 8
```
