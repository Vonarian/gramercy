
---

## 1. Core Operating Principles & Non-Negotiables

Every agent operating within this codebase must strictly observe three core pillars:

1. **Always Follow GitFlow:** Branch from `dev`, commit via Conventional Commits, merge to `dev`, verify on `dev`, then release to `main`.

2. **Strict Lines of Code (LoC) Limits:** Zero tolerance for monolithic files or sprawling functions. Keep code compact, single-responsibility, and modular.

3. **Rigid Test-Driven Development (TDD):** Red → Green → Refactor. Write failing tests **before** implementation code. Maintain ≥ 80% test coverage on business logic, repositories, and state controllers.

---

## 2. GitFlow & Branch Lifecycle

### 2.1 Branch Taxonomy

* **`main`**: Production release branch. Highly protected. Only merges from `dev` are permitted.

* **`dev`**: Integration branch for active development. All work stems from and returns to `dev`.

* **Working Branches**: Always branched directly from `dev` using strict naming conventions:

* `feat/<feature-name>`: New UI flows, state machines, or client capabilities (e.g., `feat/routine-state-machine`).

* `fix/<bug-name>`: Bug repairs and regressions (e.g., `fix/drift-batch-insert-deadlock`).

* `chore/<task-name>`: Tooling, dependency updates, and project configs (e.g., `chore/bump-drift-sqlite`).

* `refactor/<target>`: Structural code improvements without behavioral change (e.g., `refactor/extract-metric-dao`).

* `test/<test-suite>`: Unit, widget, or repository test additions (e.g., `test/routine-dao-cases`).

* `docs/<doc-name>`: Documentation updates (e.g., `docs/update-architecture-spec`).


### 2.2 Conventional Commits

All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```text
<type>(<optional-scope>): <imperative description>

```

* **Allowed Types**: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`, `style`.


* **Examples**:
* `feat(routine): implement morning protocol state progression`

* `fix(sync): resolve drift batch insert deadlock`

* `test(metric): add unit tests for summary aggregator`




### 2.3 End-to-End Release Cycle

1. **Sync `dev**`: Ensure local `dev` is up to date (`git checkout dev && git pull origin dev`).
2. **Branch Off**: Cut a new working branch (`git checkout -b feat/<name> dev`).
3. **Implement via TDD**: Write tests first, implement minimal code, and refactor within LoC limits.
4. **Local Verification**: Run the full test suite and static analysis (`flutter test`).
5. **PR / Merge to `dev**`: Open a Pull Request targeting `dev` (or merge directly if self-contained).
6. **Confirm on `dev**`: Switch to `dev`, pull upstream changes, and run the test suite to guarantee zero regression:
```bash
flutter test
```[cite: 1]

```

7. **Release PR to `main**`: Once stability is verified on `dev`, open a release PR from `dev` to `main`.
---

## 3. Strict Lines of Code (LoC) & Modularity Budgets

To ensure high maintainability, readability, and agent context fit, all Dart files must adhere to strict size ceilings:

| Target Scope | Maximum LoC | Enforcement Action |
| --- | --- | --- |
| **Dart Source File (`.dart` non-test)** | **200 lines**<br> | Extract sub-widgets, DAOs, or domain entities.

 |
| **Function / Method** | **40 lines**<br> | Decompose logic into smaller helper functions with single responsibilities.

 |
| **Flutter Widget `build()` Method** | **50 lines**<br> | Extract widget sub-trees into dedicated `StatelessWidget` classes in `presentation/widgets/`.

 |
| **Test File (`_test.dart`)** | **400 lines**<br> | Split test suites into multiple behavioral test files.

 |

### 3.1 Flutter Decomposition Strategies

* **Widget Granularity**: Never inline large UI sub-trees inside screen widgets; create granular reusable `StatelessWidget` components.


* **Logic Isolation**: Keep all business logic and side effects in dedicated state controllers and repository abstractions; widgets must only observe and render.


* **Data Models**: Avoid monster models; split state into focused, immutable data classes.

---

## 4. Test-Driven Development (TDD) Protocol

All new features, state notifiers, repositories, and bug fixes must follow the **Red-Green-Refactor** workflow:

```text
┌────────────────────────────────┐
│ 1. RED: Write Failing Test     │ (Verify requirement failure before coding)
└──────────────┬─────────────────┘
               │
               ▼
┌────────────────────────────────┐
│ 2. GREEN: Minimal Code         │ (Write simplest implementation to pass)
└──────────────┬─────────────────┘
               │
               ▼
┌────────────────────────────────┐
│ 3. REFACTOR: Clean & Modular   │ (Enforce LoC limits, optimize, keep green)
└────────────────────────────────┘

```

### 4.1 Strict TDD Rules

* **Never write production code before a failing test exists**.


* Every test must fail for the expected reason before implementing the solution.


* Run tests continuously throughout development.



### 4.2 Flutter Testing Standards

* **Tooling**: `flutter_test`, `mocktail` for mocks and spies.


* **Pattern**: Grouped behavior-driven unit, repository, and widget tests (`group('RoutineRepository', () { ... })`).


* **Execution Command**:
```bash
flutter test --coverage
```[cite: 1]

```

* **Coverage Target**: Minimum **80% line coverage** on repositories, DAOs, domain logic, and state providers.

---

## 5. Dart & Flutter Quality Directives

* **Sound Null-Safety**: Never use the force-unwrap operator (`!`) without a prior null-check assertion.

* **Immutability**: Ensure all models, UI state objects, and domain entities are immutable.

* **Separation of Concerns**: UI widgets must never trigger direct network or raw database calls; route all operations through repository and provider interfaces.

* **Widget Composition**: Build screens through shallow composition of small, focused `StatelessWidget` elements rather than monolithic builder functions.

---

## 6. Definition of Done (DoD) Checklist

Before submitting a PR or marking a task complete, verify every requirement:

* [ ] **GitFlow**: Work was performed on a `feat/*` or `fix/*` branch cut from `dev`.
* [ ] **TDD Verified**: A failing test was written first, followed by passing implementation and refactoring.
* [ ] **Flutter Tests**: `flutter test --coverage` passes with ≥ 80% coverage.
* [ ] **LoC Limits Enforced**:
* [ ] Every non-test Dart source file ≤ 200 lines.
* [ ] Every function or method ≤ 40 lines.
* [ ] Every Flutter `build()` method ≤ 50 lines.
* [ ] Every test file ≤ 400 lines.
* [ ] **Commit Format**: All commit messages follow the Conventional Commits specification.
* [ ] **Integration Confirmed on `dev**`: Branch merged/rebased to `dev` and verified clean prior to the `main` release PR.