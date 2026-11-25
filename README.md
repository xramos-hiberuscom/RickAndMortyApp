# RickAndMortyApp

SwiftUI app to search characters of *Rick and Morty* and see their detail. Runs on iOS, macOS and visionOS.

<img width="300" src="https://github.com/user-attachments/assets/b436aae1-9a42-4705-9297-a5db5c7d13a6" />
<img width="300" src="https://github.com/user-attachments/assets/a15681a7-8b1a-4120-89a3-7dda0a15f198" />
<img width="300" src="https://github.com/user-attachments/assets/490e1662-7c2b-4141-a495-69a92d88c28e" />


## How to use the app

1. Open `RickAndMortyApp.xcodeproj` in Xcode and run the `RickAndMortyApp` scheme. No API key or extra setup is needed.
2. On the **Characters** screen, type a name in the search field (for example `rick`). Results appear after a short pause while you type.
3. Tap a character to open its **detail**: photo, status (green = Alive, red = Dead, gray = Unknown), species and gender.
4. Go back to return to your results.

Search states: an explanation when the field is empty, a progress indicator while loading, the list, "No Results" when nothing matches, and an error message otherwise. The detail screen also offers **Retry** on errors.

### Running the tests

```bash
xcodebuild test -project RickAndMortyApp.xcodeproj -scheme RickAndMortyApp \
  -destination 'platform=iOS Simulator,name=<a simulator you have installed>'
```

- **Unit tests** use Swift Testing. The network is replaced with `URLProtocol` stubs and mocks.
- **UI tests** use XCTest. They launch the app with the `-UITesting` argument, which (Debug builds only) swaps the network for fixed characters, so they are deterministic and need no internet. They cover navigation and accessibility.

## Public API used

[The Rick and Morty API](https://rickandmortyapi.com/documentation) (`https://rickandmortyapi.com/api`), public and unauthenticated:

| Endpoint | Used for |
|---|---|
| `GET /character?name=<text>` | Search. Returns a paginated envelope (`info`, `results`). Only the first page is used. |
| `GET /character/{id}` | Detail of one character. |

When a search has no matches the API answers **404**. The app treats this as "no results", not as an error.

## Architecture

Clean Architecture in three layers plus a small network layer. Dependencies point inwards: Presentation → Domain ← Data.

```
RickAndMortyApp/
├── App/            AppEnvironment: composition root
├── Network/        NetworkManager, Endpoint, NetworkError
├── Data/           DataSources, Response models (DTOs), TimedCache
├── Domain/         Models, Repositories, UseCases
└── Presentation/   Scenes (View + ViewModel), Components, DesignSystem
```

### Responsibilities

| Layer | Responsibility | Knows about |
|---|---|---|
| **Network** | Builds the `URLRequest` from an `Endpoint`, performs it with `async/await`, validates the HTTP response, decodes JSON and maps failures to `NetworkError` (including 404 → `.notFound`). Knows nothing about characters. | Foundation |
| **Data** | `CharacterRemoteDataSource` calls the endpoints and returns DTOs (`ServerCharacter`, `ServerArray`). DTOs mirror the JSON and stay in this layer. | Network |
| **Domain** | `Character` and its enums are the app's own models. `CharacterRepository` maps DTOs to models, turns "not found" into `[]` / `nil`, and owns the search cache. Use cases (`SearchCharactersUseCase`, `GetCharacterUseCase`) expose one operation each. | Data (via protocols) |
| **Presentation** | Views render state; `@Observable` ViewModels hold that state and drive the use cases. The Design System centralises spacing, sizes, corner radius, border and opacity. | Domain |
| **App** | `AppEnvironment` wires the concrete objects and provides the test stubs for UI tests. | Everything |

### Decisions

- **DTO ≠ domain model.** API changes stay inside Data; the UI never sees `ServerCharacter`.
- **Protocols at every boundary** (`NetworkManagerContract`, `CharacterRemoteDataSourceContract`, `CharacterRepositoryContract`, use case contracts). Each layer is tested in isolation with mocks.
- **Use cases** keep ViewModels independent from repositories and give a single place for each business operation.
- **One shared repository** (in `AppEnvironment`) so its cache lives as long as the app, not as long as a screen.
- **Native SwiftUI and Swift concurrency only**: `async/await`, `@Observable`, `NavigationStack`. No third-party dependencies.
- **Per-screen helper files**: `…A11y.swift` (accessibility identifiers and labels) and `…Localizable.swift` (texts), to avoid magic strings in views.
- **State as an enum** in each ViewModel (`idle / loading / loaded / empty / error`), so impossible combinations cannot be represented.

## In-memory cache

**Search results** (`TimedCache`, used by `CharacterRepository`):

- Cached **per query** for **2 minutes** (`CharacterRepository.searchCacheTTL`).
- While an entry is valid it is returned **without a network call**. When it has expired, the data is fetched again and the entry is replaced.
- The key is the query trimmed and lowercased, so `rick`, `RICK` and ` rick ` share one entry.
- Empty results are cached (a repeated search with no matches does not hit the API). **Errors are not cached**, so the next attempt goes to the network.
- Memory only: the cache is lost when the app closes. The clock is injectable, so expiry is tested without waiting.
- Limitation: two identical searches that start before the first finishes both go to the network (no in-flight deduplication).

**Images** (`ImageLoader` + `CachedAsyncImage`, replacing `AsyncImage`):

- Two levels: `NSCache` in memory (decoded images, evicted by the system under memory pressure) and `URLCache` on disk (20 MB memory / 100 MB disk), so images also survive relaunches.
- An image already in memory is shown immediately, with no placeholder flash when scrolling or navigating back.

## Task cancellation

Search happens while the user types, so older requests must never overwrite newer ones (`CharacterSearchViewModel`):

1. Each `search(_:)` call **cancels the previous `Task`** before starting its own.
2. The task first waits **300 ms** (debounce). If the user types again meanwhile, it is cancelled during the sleep and no request is made.
3. After the `await` on the use case, `Task.checkCancellation()` runs **before** publishing. A request that finishes after being cancelled therefore never reaches the UI, even if its network call could not be interrupted in time.
4. `CancellationError` and `URLError.cancelled` (mapped to `NetworkError.transport(.cancelled)`) are treated as "superseded", not as errors, so no error screen flashes.
5. An empty query cancels the current search and returns to the idle state.

On the detail screen the load runs in SwiftUI's `.task`, which cancels it automatically when the view disappears.

## Accessibility

- Search rows are read as one element ("Rick Sanchez, Human"); decorative images and the status colour dot are hidden from VoiceOver (the status is also given as text).
- The end of a search is **announced** ("3 characters found" / "No characters found"), since results appear without moving focus.
- Layouts use system text styles and keep working with the largest accessibility text sizes. UI tests include `performAccessibilityAudit`.
