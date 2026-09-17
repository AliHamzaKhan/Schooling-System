# Meri Taleem shared UI

The `shared` Flutter package is the source of truth for design tokens, common
application components, responsive behavior, motion, authentication, messaging,
and cross-portal services used by the school and admin applications.

Import the public package API rather than files below `lib/src`:

```dart
import 'package:shared/shared.dart';
```

## Foundations

| Foundation | Public API | Rule |
| --- | --- | --- |
| Color | `AppColors`, `AppTheme.light()` | Use semantic colors or the active `ColorScheme`; do not add feature-local brand colors. |
| Type | `AppTypography` | Use the shared scale and allow system text scaling. Do not clamp text merely to prevent overflow. |
| Spacing | `AppSpacing` | Use the 8 px rhythm and named container/gutter values. |
| Shape | `AppRadius` | Use component aliases (`button`, `card`) before raw radii. |
| Depth | `AppElevation` | Use borders and shared surface fills; reserve glows for the documented AI treatment. |
| Motion | `AppMotion`, `FadeSlideIn`, `Pressable`, `Shimmer` | Motion is optional enhancement. Widgets must honor `MediaQuery.disableAnimationsOf(context)`. |
| Layout | `Breakpoints`, `AppScaffold` | Reflow at shared breakpoints and verify phone, tablet, and desktop widths. |

## Component catalogue

| Need | Component | Required usage notes |
| --- | --- | --- |
| Primary action | `PrimaryButton` | One dominant action per region; use `isLoading` to prevent duplicate submission. |
| Secondary action | `GhostButton` | Use for cancel, back, or lower-emphasis actions. |
| Grouped content | `AppCard` | Supply `semanticLabel` when the whole card is interactive. |
| Text entry | `AppTextField` | Always provide a visible `label`; use helper and error text instead of placeholder-only instructions. |
| Tabular data | `AppDataTable` | Supply a concise `semanticLabel`; the table scrolls horizontally at narrow widths and large text. |
| Empty/error/loading | `AppStateView` | State the outcome and recovery action. Error/loading announcements are live regions. |
| Confirm/alert | `showAppConfirm`, `showAppAlert`, `showAppDialog` | Use destructive styling only for destructive actions; do not make a destructive action the default dismissal. |
| Auth input | `GlassInput` | Existing authentication treatment only; new application forms use `AppTextField`. |
| Data visualization | `AreaChart` | Pair visual data with a readable text value or table. |

Example:

```dart
AppCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('School details', style: AppTypography.titleLg),
      const SizedBox(height: AppSpacing.stackMd),
      AppTextField(
        controller: nameController,
        label: 'School name',
        required: true,
      ),
      const SizedBox(height: AppSpacing.stackLg),
      PrimaryButton(label: 'Save changes', onPressed: save),
    ],
  ),
);
```

## Required states

Every data-backed screen must deliberately implement:

1. Initial loading without fake progress.
2. Empty content with context and, when appropriate, a next action.
3. Recoverable failure that does not expose exception text or private data.
4. Loaded content.
5. Submission progress and an honest success, failure, or uncertain result.
6. Disabled/read-only state when the user can view but cannot act.

Do not use color alone to communicate a state. Keep the affected school,
session, class, child, or trip visible when an action could otherwise be
ambiguous.

## Accessibility and responsive acceptance

Representative component and feature tests must cover:

- semantics for controls, interactive cards, tables, and asynchronous states;
- keyboard traversal and visible focus for web/desktop workflows;
- 200% text without clipped content or unreachable actions;
- 320 px phone width plus tablet and desktop layouts;
- reduced motion with `disableAnimations: true`;
- sufficient contrast using shared foreground/background pairs;
- validation and status communication that does not depend on color alone.

Run the package gates from this directory:

```sh
flutter analyze
flutter test
```

Exceptions require a dated note in the product progress tracker with the owning
screen, reason, user impact, and follow-up packet. A local exception must not
silently introduce a competing token or component system.
