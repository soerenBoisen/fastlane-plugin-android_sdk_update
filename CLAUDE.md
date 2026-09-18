# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A _fastlane_ plugin (Ruby gem) that provides three fastlane actions for Android CI builds:

- `android_sdk_update` — installs/updates Android SDK packages (via Homebrew/Linuxbrew cask on macOS, or direct download on Linux) and accepts SDK licenses.
- `gradle_update` — downloads and installs a specific Gradle distribution (Linux only).
- `gradle_wrapper` — runs `gradle wrapper --gradle-version ...` against an Android project using a Gradle install produced by `gradle_update` (or `GRADLE_HOME`).

These actions are typically chained in a Fastfile: `gradle_update` → `gradle_wrapper` → `android_sdk_update`.

## Commands

```bash
bundle install         # install dependencies
rake                    # default task: runs rspec + rubocop — run this before considering a change done
rspec                   # run tests only
rspec spec/android_sdk_update_action_spec.rb -e 'fails without build tools version'  # run a single example
rubocop                 # style check only
rubocop -a               # auto-fix style issues
```

There is no separate lint/build step beyond rubocop; `rake` (spec + rubocop) is the full CI check (see `circle.yml`, `.travis.yml`).

## Versioning

This project follows [semantic versioning](https://semver.org) (MAJOR.MINOR.PATCH). Every fix or feature change to this plugin must bump `VERSION` in `lib/fastlane/plugin/android_sdk_update/version.rb` as part of the same change — bump the patch digit for backwards-compatible fixes, the minor digit for backwards-compatible features, the major digit for breaking changes. Do this automatically; don't wait to be asked. Doc-only changes (e.g. README) don't need a version bump.

See the "Publishing a new release" section in `README.md` for the git-based release flow (this fork isn't published to RubyGems).

## Architecture

- `lib/fastlane/plugin/android_sdk_update.rb` is the plugin entrypoint: it globs and `require`s every `.rb` file under `actions/` and `helper/`, so a new action file just needs to exist in `lib/fastlane/plugin/android_sdk_update/actions/` to be picked up — no manual registration.
- Each action lives in `lib/fastlane/plugin/android_sdk_update/actions/*.rb` as a `Fastlane::Actions::*Action < Action` class following the standard fastlane plugin action shape: `self.run(params)` (entry point), `self.available_options` (declares `FastlaneCore::ConfigItem`s, env var names, and defaults), `self.output`/`self.return_value`/`self.return_type`, and `self.is_supported?(platform)` (all three actions only support `:android`).
- Actions communicate via `Actions.lane_context` `SharedValues`, not return values alone:
  - `AndroidSdkUpdateAction` sets `SharedValues::ANDROID_SDK_HOME`.
  - `GradleUpdateAction` sets `SharedValues::GRADLE_HOME` and `SharedValues::GRADLE_BIN`.
  - `GradleWrapperAction`'s `gradle_dir` option defaults to reading `SharedValues::GRADLE_HOME` from the lane context (falling back to `ENV["GRADLE_HOME"]`), which is how it picks up the install location from a prior `gradle_update` call in the same lane.
- OS branching is done inside each action's `determine_sdk`/`determine_gradle` method: macOS uses Homebrew/the `fastlane-plugin-brew` dependency; Linux downloads a zip via `wget` and extracts it with `unzip`, all executed through `FastlaneCore::CommandExecutor.execute`. Any other OS calls `UI.user_error!`.
- `android_sdk_update` resolves `compile_sdk_version`/`build_tools_version` with this precedence: explicit action param → `gradle.properties` in the project root (parsed via the `java-properties` gem) → `UI.user_error!` if neither is set.
- `AndroidSdkUpdateHelper` (`helper/android_sdk_update_helper.rb`) is currently just a stub/example method; helpers are the intended place for logic shared across actions.
- Tests (`spec/android_sdk_update_action_spec.rb`) drive actions indirectly by parsing an actual `Fastfile` string with `Fastlane::FastFile.new.parse(...).runner.execute(:test)`, not by calling action classes directly — follow this pattern when adding new specs.
