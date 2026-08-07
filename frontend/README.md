# ShopSwift SwiftUI Frontend (Phase 1)

This folder contains the fully Swift client for the prototype.

## Xcode setup

1. Create a new iOS App project named **ShopSwift** (SwiftUI, Swift).
2. Drag the `App`, `Core`, `Features`, `Shared`, and `Resources` folders into the app target.
3. Remove Xcode's generated `ContentView.swift` and generated `@main` App file if they conflict with these files.
4. Use iOS 17+.
5. Start the Vapor backend first.
6. Simulator: keep `apiBaseURL = http://127.0.0.1:8080`.
7. Physical device: change `apiBaseURL` to the development computer's LAN IP and allow local-network/HTTP development access as needed.

## Frontend/backend flow

SwiftUI View -> Service -> APIClient -> Vapor REST endpoint -> Fluent -> PostgreSQL -> JSON response -> Swift model -> SwiftUI View.

## PWA note

A real browser PWA requires browser assets (HTML/CSS/JavaScript or WebAssembly bootstrap files). `backend/Public` contains a small PWA demonstration that consumes the **same REST API**, while this folder remains the fully Swift frontend requested by the assignment. A later phase can replace the thin browser layer with a Swift/Wasm UI if the supervisor requires browser UI logic itself to be authored in Swift.

## Annotated files (developer notes)

- I added concise explanatory comments to key UI files under `Features/` (Products, Cart, Authentication).
- The comments explain what each view loads, when network calls occur, and any important UI state decisions.

These comments are intentionally short to make the SwiftUI flow easier to scan during Phase 1 development.
