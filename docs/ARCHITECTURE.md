# HER AREA — Enterprise Monorepo Architecture & Multi-Application Engineering Handbook

This document details the architectural principles, codebase boundaries, dependency injection graph, and release strategies for the **HER AREA** multi-application workspace.

---

## 1. Executive Summary & Monorepo Topology
HER AREA is engineered as a structured **Monorepo** containing three independent client applications powered by a shared UI design system and networking core:

```
HER_AREA (Workspace Root: c:\Users\DHANISHA IT S\Desktop\Her Area)
│
├── app_user/          # Customer App (iOS, Android, Mobile Web) — For Brides
├── app_vendor/        # Vendor App (Android, Web Portal) — For Artisans & Boutiques
├── app_admin/         # Admin App (Desktop & Web Console) — For Platform Governance
│
├── shared/            # Common Flutter Library (Consumed by all 3 clients)
│   ├── lib/
│   │   ├── core/      # Base architecture contracts and exception definitions
│   │   ├── theme/     # Material 3 design tokens (AppColors, AppTypography, AppTheme)
│   │   ├── widgets/   # Atomic UI library (CustomButton, CustomCard, StatusBadge, etc.)
│   │   ├── models/    # Domain data contracts (Store, Product, Review, Category)
│   │   ├── services/  # Abstract HTTP client interface & logging hooks
│   │   ├── utils/     # Currency formatting & input validator functions
│   │   ├── constants/ # Environment configurations & regex rules
│   │   └── common/    # Responsive wrapper layouts & display utilities
│   └── pubspec.yaml
│
├── backend/           # Future Django REST Framework API Engine & PostgreSQL Schema
└── docs/              # Enterprise specifications & documentation
```

---

## 2. Design Philosophy: Zero Code Duplication
By centralizing all atomic UI elements and domain models inside `shared`, we enforce brand consistency across the entire ecosystem while eliminating redundant boilerplate:
- **Consistent Styling:** A change to `AppColors.primaryRuby` or `AppTheme.lightTheme` in `shared` instantly elevates the aesthetics of `app_user`, `app_vendor`, and `app_admin` simultaneously.
- **Robust Layout Flexibility:** All shared buttons and containers utilize resilient flex wraps and responsive breakpoints (`ResponsiveLayout`), preventing UI overflows across mobile phones, tablets, and ultra-wide desktops.

---

## 3. Clean Architecture & State Management (Riverpod)
Each independent client app adheres strictly to **Clean Architecture** patterns, divided into clear horizontal strata:
1. **Presentation Layer (`features/*/presentation/`):** Contains GoRouter route configurations, interactive screens, and view widgets. Communicates entirely through reactive `ConsumerWidget` interfaces.
2. **State & Controller Layer (`core/state/` or feature state Notifiers):** Managed via **Riverpod v2 (`flutter_riverpod`)**. Uses immutable state classes (`Notifier` and `StateProvider`) to track active categories, live product filters, authentication tokens, and theme preferences.
3. **Data & Repository Layer (`data/`):** Implements repository contracts and mock data feeds during prototyping, ready for drop-in substitution with real HTTP services via `IApiClient` during backend phase.

---

## 4. Navigation Strategy (GoRouter & StatefulShellRoute)
All client applications leverage **GoRouter** for declarative, URL-addressable navigation:
- **Deep Linking Readiness:** Every screen is mapped to explicit static path strings (e.g. `/dashboard`, `/product-details/:id`).
- **Stateful Bottom Navigation Bar:** Both `app_user` and `app_vendor` utilize `StatefulShellRoute.indexedStack` to preserve scrolling positions and active tab inputs when switching between Home, Catalog, Enquiries, and Profile branches.

---

## 5. Build & Verification Guide
To execute automated verification across the workspace:

### Test Shared Library:
```powershell
cd shared
flutter analyze
flutter test
```

### Test Customer Application (`app_user`):
```powershell
cd app_user
flutter analyze
flutter test
```

### Test Vendor Application (`app_vendor`):
```powershell
cd app_vendor
flutter analyze
flutter test
```

### Test Admin Portal (`app_admin`):
```powershell
cd app_admin
flutter analyze
flutter test
```

All three client applications are verified to build cleanly and function independently without mutual interference!
