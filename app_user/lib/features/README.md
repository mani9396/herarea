# Feature-First Architecture Directory Guide — HER AREA

This folder (`lib/features/`) implements strict **Feature-First Architecture**, where each business feature exists as an autonomous, self-contained module.

---

## 🏛️ Module Structure
Every feature directory (such as `auth`, `onboarding`, `discovery`, `store`, `search`, and `profile`) MUST adhere to the following layer segregation:

1. **`presentation/`**: 
   - **`screens/`**: Complete page containers and view routing anchors.
   - **`widgets/`**: Feature-specific UI components (not globally shared).
   - **`controllers/`**: Riverpod state notifiers and UI logic handlers.

2. **`domain/`**:
   - **`models/`**: Immutable entities and business data representations.
   - **`repositories/`**: Abstract repository contract definitions.

3. **`data/`**:
   - **`repositories/`**: Concrete repository implementations (Mock & HTTP).
   - **`datasources/`**: Local cache handlers and REST/GeoDjango endpoint callers.

---

## ⚠️ Architectural Rules
- **No Cross-Feature Data Imports:** A feature cannot import another feature's data repository directly; communicate purely via shared core state or domain models.
- **UI Design System Exclusivity:** All presentation components must consume typography, spacing, and colors exclusively from `lib/core/theme/`.
