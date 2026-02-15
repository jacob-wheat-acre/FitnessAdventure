# Fitness Adventure

**Fitness Adventure** is a SwiftUI fitness app that turns workouts into RPG-style progression: XP, levels, quests, enemies, and unlocks.

This is an actively developed personal project.

## Tech Stack
- Swift / SwiftUI
- HealthKit (workout + activity integration)

## Current Features
- Character progression (levels / XP)
- Quest selection + quest flow
- Combat encounters (turn-based selection)
- Game data catalogs (attacks, enemies, narrative)
- Persistence layer (local save)

## Project Structure
- `FitnessAdventure/App` — app entry + root navigation
- `FitnessAdventure/Views` — SwiftUI screens by feature area
- `FitnessAdventure/ViewModels` — UI state + orchestration
- `FitnessAdventure/Models` — core data types
- `FitnessAdventure/GameRules` — game logic (combat/progression/workout rules)
- `FitnessAdventure/GameData` — catalogs/content (enemies, attacks, narrative)
- `FitnessAdventure/Services` — integrations (e.g., HealthKit)
- `FitnessAdventure/Persistence` — save/load

## Getting Started
1. Clone the repo
2. Open `FitnessAdventure.xcodeproj` in Xcode
3. Select an iPhone simulator
4. Build & Run (⌘R)

> Note: HealthKit features require running on a real device for full functionality.

## Versioning / Builds
Builds are tagged in Git (e.g., `v1.1-build2`). See `CHANGELOG.md` for details.

## Roadmap (Build 3+)
- Expand quest system (artifact quests and validation)
- Improve progression pacing and rewards
- Refine UI flow + polish
- Add lightweight tests around core rules (combat/progression)

## License
All rights reserved (personal project).
