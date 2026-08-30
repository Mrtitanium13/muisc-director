# Music Director — Workspace Rules

Flutter app: AI Suno prompt generator + audio analyzer. Dart SDK ^3.11.0.
User-scope rules in `~/.zcode/AGENTS.md` apply first; this file narrows them for this repo.

## Architecture
- State: Riverpod (`flutter_riverpod` + `hooks_riverpod` + `flutter_hooks`). Do not introduce other state management.
- Routing: `go_router` (see `lib/app/router/app_router.dart`).
- Network: `dio` via `lib/core/network/dio_client.dart`. Do not create ad-hoc HTTP clients.
- Local storage: Hive (`hive` / `hive_flutter`) + `shared_preferences`.
- Config/secrets: `flutter_dotenv` via `.env` (template: `.env.example`). Never commit `.env`; never hard-code keys.
- Prompt/domain data lives in `lib/core/constants/` — large const data files. Extend existing files/patterns rather than creating parallel systems.

## Verification (run before reporting done)
1. `flutter analyze` — must pass; project lints via `flutter_lints/flutter.yaml` (analysis_options.yaml).
2. Relevant tests: `flutter test` (suite lives in `test/`; run a single file when scope is narrow, e.g. `flutter test test/api_paths_test.dart`).
3. Logic touching prompt generation or API payloads: verify against existing tests/fixtures in `test/` before assuming behavior.

## Conventions
- Verify dependency APIs against `pubspec.lock` / installed packages, not memory.
- Match existing naming and error-handling style in `lib/core/` and `lib/features/`.
- No new dependencies without explicit approval (pubspec changes are user-visible decisions here).
