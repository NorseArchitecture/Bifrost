# CLAUDE.md — Bifröst (Norse.Orchestration)

Cold-start context for any Claude Code session in this repo. Where a rule here conflicts with a default behavior, this file wins.

## 1. What This Repository Is

**Bifröst** is the local developer meta-repository for the Norse Architecture — the rainbow bridge between the realms. It exists for exactly one purpose: **clone once and run.** It composes every resource required to run and develop the platform — services, databases, queues, and configuration — via a .NET Aspire AppHost under the `Norse.Orchestration.*` namespace.

It is a **reference composition, not a product**. Consumers of the Norse Architecture are expected to build their own bridge: take the realm repos they need as submodules, write their own AppHost, and swap the runtime containers for whatever direction their platform is going. Contributions land in the realms; pull requests here should be rare — composition fixes, not features.

**Every Claude Code session starts from Bifröst.** The bridge is the working root: all realms are checked out beneath it, and **Glitnir** rides alongside as the design court — every spec, plan, and proof of concept that enters the record as part of a rendered verdict lives there. Realm CLAUDE.md files reference Glitnir documents by sibling-relative path (`../Glitnir/docs/...`).

**State of the union (2026-07-01):** the migrations framework — the first piece of runtime composition this repository exists to prove out — has landed end to end. Six realms shipped their slice in strict dependency order, each behind its own ship gate (PR merged, CI green, tagged, published to NuGet): Asgard declared `IMigrationContributor`, Midgard built the `MigrationRunnerService` runner, Urðarbrunnr shipped the EF foundation plus this platform's first Roslyn source generator, Himinbjörg proved it against the hardest brownfield case there is (full ASP.NET Core Identity v3 + OpenIddict), Yggdrasil's migrations service went from a placeholder stub to a permanent three-line `Program.cs`, and Bifröst wired a Postgres primary + streaming replica into the Aspire dashboard and pointed the migrations service at it. Run `dotnet run --project src/Orchestration.AppHost` today and `norse_identity` stands up for real. Full narrative: `../Glitnir/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md`. This is the template every future bounded context now follows to get its own `norse_{context}` database online — Mímisbrunnr already proved it days later, standing up `norse_reference` with zero new framework code.

**State of the union (2026-07-25):** the transport-neutral invocation pipeline has also landed. Asgard shipped `Outcome<T>` (`Abstractions.Contracts`, the platform's second discriminated union) and the `GatewayGenerator` (`Contract`/`InProcessHost`/`WireHost` emission from `[GenerateGateway]`); Midgard shipped the four-stage mediator pipeline over `martinothamar/Mediator`; Yggdrasil's Task 13/14 turned `InProcessHost` mode on for the first time anywhere on the platform (PR #36, Asgard tag v0.0.10). Doing so surfaced two gaps in already-shipped packages, tracked as Open Decision #2 below. Doctrine for the platform's two discriminated unions (`Result<T>` vs `Outcome<T>`, why they rhyme and why they're never siblings) is now recorded at `../Glitnir/docs/the-two-unions.md`.

**Peer repositories** sit beside Bifröst in the same parent directory and are not submodules of it:

| Repository | Local path | Purpose |
|---|---|---|
| Ginnungagap (`.github`) | `../.github` | The primordial void: org-default community-health files, reusable GitHub Actions workflows (`ci-build-test.yml`, `publish-nuget.yml`, `create-release.yml`, `update-bifrost.yml`), config scatter (`scatter-the-runes.ps1`, `manifest.psd1`), and the Law of the Æsir. Referenced by realms as `NorseArchitecture/.github/.github/workflows/*.yml@master`. |

## 2. The Naming Model

**Repositories are named for the lore; projects and namespaces are named for the function.** Open the org and you tour the cosmos; open the solution and every project says what it does. The codename never appears as an operational identifier — `Bifrost` is the repo name and the story, `Norse.Orchestration` is the code.

| Repository (lore) | Namespace (code) | Function |
|---|---|---|
| Svartálfheim | `Norse.Primitives.*` | The forge: `Result<T>`, the parsing stack, and the analyzers and BuildCheck rules that strike when law is broken |
| Asgard | `Norse.Abstractions.*` | Declared law: contracts, attribute model, plugin interfaces, mediator law |
| Midgard | `Norse.Infrastructure.*` | Embodied law: concrete persistence, mediator runtime, API, UI Composition framework |
| Urðarbrunnr | `Norse.Persistence.*` | The persistence realm — any database/data-store mechanism, not EF-only. `Norse.Persistence.EntityFramework.*` (entity base types, DbContext foundations, conventions, value converters, migrations chassis) is the live vendor family; a different ORM, native driver, or document/search store lands as its own sibling, mirroring Heimdall's `AuthN.Components.FluentUI` drop-in pattern |
| Ratatoskr | `Norse.Messaging.*` | The messaging realm — any message-broker/transport mechanism, not NServiceBus-only. `Norse.Messaging.NServiceBus.*` (endpoint configuration, saga infrastructure, message conventions, transport wiring) is the live vendor family; a different broker or messaging library lands as its own sibling, mirroring Urðarbrunnr's pattern — the squirrel that carries messages between the realms |
| Yggdrasil | `Norse.Hosting.*` | Hosting runtimes and deployables: web server, worker, migration service, WASM client, MAUI app, and the BlazingStory catalog host (`Hosting.Stories.Client`/`.Server`) |
| Himinbjörg | `Norse.Identity.*` | EF persistence for ASP.NET Identity and OpenIddict: entities, conventions, and migrations; sealed server-side, never referenced from WASM or MAUI |
| Heimdall | `Norse.AuthN.*` | The authn story on Himinbjörg's identity record: login, register, forgot-password, 2FA setup, recovery, and reset, uniform across Blazor Server, WASM, and MAUI, with the backing gRPC service |
| Mímisbrunnr | `Norse.Reference.Data` | Entities, view models, TSV seeders (nietras Sep), and migrations for canonical reference data — ISO country/currency codes, IANA time zones |
| Mímir | `Norse.Reference.Components` / `.Web.Server` / `.Worker` | Serving layer on Mímisbrunnr: Blazor components, gRPC service host, and the background worker that keeps reference data current |
| Naglfar | `Norse.DesignSystem.*` | The token pipeline (`@norsearchitecture/design-tokens`, Style Dictionary) only. **npm-only, no .NET** — narrowed 2026-07-12 to "no hand-authored C#": `DesignSystem.Tokens` is a single 100%-generated .NET package (`FluentTokenSeed` + `norse-design-tokens.css`), packed alongside the npm package in the same release step — `DesignSystem.Stories` split out to Bragi 2026-07-12, the same day it landed here |
| Bragi | `Norse.DesignSystem.Stories` | Content-only RCL of `.stories.razor`/markdown catalog pages for the platform's Blazor components; the runnable BlazingStory host lives in Yggdrasil, not here (`../Glitnir/docs/Platform/specs/2026-07-12-designsystem-stories-hosting-design.md`, superseded in part — see the same-day addendum recording the split from Naglfar) |
| Glitnir | — (documents only) | Design court: specs, plans, and proof-of-concept verdicts |
| **Bifröst** (this repo) | `Norse.Orchestration.*` | Aspire AppHost composing the local development environment |
| Ginnungagap (`.github`) | — (org-defaults only) | The primordial void: community-health files, reusable workflows, config scatter, and the Law of the Æsir — everything that exists before and beneath the realms |

**Urðarbrunnr's widened scope is live (corrected 2026-07-25 — previously logged here as still staged):** the rename from `Norse.EntityFramework.*` to `Norse.Persistence.EntityFramework.*` merged to `master` via PR #31 and shipped in tag `v0.0.4`. Yggdrasil's `Directory.Packages.props` already pins the new package family (`Norse.Persistence.EntityFramework`/`.Design`/`.Design.PostgreSQL`/`.Design.SqlServer`/`.PostgreSQL`/`.SqlServer`) at that version. Two pre-rename project folders (`EntityFramework.Configuration`, `EntityFramework.Migrations`) still sit under Urðarbrunnr's `src/` but are no longer wired into `Urdarbrunnr.slnx` — orphaned, not a doc problem, but don't be surprised they're there.

**The brand prefix is build-injected, never file-encoded.** Project folders and `.csproj` files are brand-free (`src/Primitives/Primitives.csproj`); each realm's root `Directory.Build.props` injects `Norse.$(MSBuildProjectName)` as both `AssemblyName` and `RootNamespace`. A fork rebrands by changing `Norse` once per realm — no project renames, no slnx surgery; `namespace Norse.*` declarations in code do not follow (that's the fork's own act). Solution folders in `Bifrost.slnx` carry the function names (`/Primitives/`), one per realm.

**Aspire ecosystem names are kept, not fought:** the AppHost project keeps its Aspire-conventional shape — project `Orchestration.AppHost`, assembly `Norse.Orchestration.AppHost`. Don't invent novel names for things the ecosystem has already named.

## 3. Submodules

Each platform realm is a git submodule. Two non-negotiable conventions:

- **Relative URLs** (`../Svartalfheim.git`), resolved against whatever remote Bifröst was cloned from — one `.gitmodules` serves HTTPS and SSH clones identically. A fork of Bifröst resolves submodules against the fork's owner and fails loudly unless the realms are forked alongside it. **That behavior is deliberate** — forking the bridge is the signal to build your own, not a workflow we accommodate.
- **Branch tracking on `master`** (`-b master` in `.gitmodules`). `git submodule update --remote` pulls each realm's tip; this repo exists for developer productivity, so tracking beats SHA-pinning here.

New realm lands? `git submodule add -b master ../{Realm}.git` and update the realm tables in both README.md and this file in the same change.

## 4. What Belongs Here (and What Doesn't)

**Belongs here:**

- `Orchestration.AppHost` (assembly `Norse.Orchestration.AppHost`) — the Aspire AppHost and its container/resource profile for the local environment.
- `.gitmodules`, the realm submodules, and repo-level build plumbing shared across the composition.

**Does not belong here:**

- **Runtime endpoints, hosting chassis, service code** — that's Yggdrasil (`Norse.Hosting.*`) and below. Bifröst composes what the realms provide; it never provides.
- **`ServiceDefaults`** — ruled 2026-06-28: Midgard (`Norse.Infrastructure.*`); never Yggdrasil, never Bifröst, Aspire convention notwithstanding.
- **Anything a specific company or product needs** — product code is sovereign and lives under its own root, in its own repos, on its own bridge.

When in doubt: if deleting Bifröst would break anything other than the local dev experience, the thing is in the wrong repo.

## 5. Conventions

Code style, indentation, `var`, accessibility, and naming rules: global `~/.claude/CLAUDE.md`. Bifröst-specific additions:

- **`.slnx` solution format** (`dotnet new sln --format slnx`); project layout `src/{ProjectName}/{ProjectName}.csproj` with brand-free project names (see §2). Each realm's solution file is named for the lore (`Svartalfheim.slnx`), matching its repo.
- **`sealed` by default** — `internal sealed` is the default for every new type; open only when a concrete subtype exists.
- **Relative paths only in documents** (hard law, 2026-06-11): repo-relative or workspace-relative (`../Glitnir/docs/...`); machine-local absolute paths never enter the record — environment variables name machine locations when unavoidable.

## 6. Process

- **NEVER branch Bifröst itself.** Stay on `master` — near-absolute, not a default-with-exceptions. The one narrow exception requires both: (1) the feature genuinely lives in Bifröst's own tracked files (`Orchestration.AppHost`, `Bifrost.slnx`, `.gitmodules`, root build plumbing), not a submodule pointer bump; and (2) every other realm submodule is on `master`, nothing else in flight. If either fails, stay on `master`. `master` absorbs constant bot traffic (CPM bumps, config scatter, release fan-in, submodule pointer updates) that a feature branch would have to carry and reconcile against — expensive and painful in a way an isolated realm repo isn't.
- **No automatic git commits.** Stage and show the diff; the human commits. When in doubt, stop and wait.
- **No force-pushing to `master`.** No skipping git hooks. No committing secrets — local dev configuration uses user secrets or Aspire-managed values, never checked-in credentials.
- **Implementation is subagent-driven and test-driven, always.** `superpowers:subagent-driven-development` is the default — `executing-plans` is the narrow separate-session fallback, never interchangeable. Pairs with `superpowers:test-driven-development` on every coding task. Full rule: `../Glitnir/CLAUDE.md` §2.8.
- **README.md and CLAUDE.md stay in sync — boy-scout law.** The pair tells one story at two altitudes: README is the public narrative, CLAUDE.md the working law. Any change touching what either describes — submodules, naming, conventions, composition — updates both in the same change, and the realm tables in both files must match `.gitmodules` exactly. Touch a repo, check its pair before you leave.

## 7. CI/CD Patterns

Coverage CI and release pipeline proven on Svartálfheim (PRs #4, #6). Full design and gotchas: `../Glitnir/docs/Platform/specs/2026-06-26-code-coverage-ci-design.md`.

**Realm adoption — two files:**

1. `tests/Directory.Build.props` — `<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="18.*" />` (hoisted; alphabetical order).
2. `.github/workflows/ci.yml` — `permissions: pull-requests: write` at workflow level; `with: minimum_coverage: <N>` on the `gate` job.

**Non-obvious bits:**
- **`18.*` only** — `17.*` fails at MTP 2.x startup with `MissingMethodException`. No `17.x` works.
- **No `.runsettings`** — silently ignored by MTP; `git rm` any that exist.
- **Coverage floor is 0.1** in the shared workflow (`FLOOR=0.1` in `ci-build-test.yml`, temporarily lowered until the ASP.NET Identity template is out of Yggdrasil — see Ginnungagap's `CLAUDE.md`); `minimum_coverage` input default is `0`. Effective = `max(0.1, input)`. Corrected 2026-07-25 — previously logged here as 60, which the workflow source does not support.

## 8. Open Decisions

Raise these before writing code that touches them; do not silently proceed:

1. **Container profile composition — Postgres decided and live; broker, cache, and any further identity-provider containers still open.** The dashboard-first goal cleared its first milestone: Postgres primary+replica is wired into the Aspire dashboard (`src/Orchestration.AppHost/AppHost.cs`), and the migrations service — the first real runtime endpoint Yggdrasil hosts — runs to completion against it, standing up `norse_identity` with the full ASP.NET Core Identity v3 + OpenIddict schema. Full design and rollout: `../Glitnir/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md`. Still open: broker and cache containers, any additional identity-provider containers, and how a consumer swapping them out is expected to express that.
2. **Asgard's `GatewayGenerator` can't see `NorseGatewayEmissionMode` — `InProcessHost` mode silently falls back to `Contract` mode.** Never declared `CompilerVisibleProperty` platform-wide; worked around locally in Yggdrasil's two `.csproj` files only. Midgard's four mediator `Behavior` classes also needed a per-consumer `InternalsVisibleTo` grant for cross-assembly construction — fixed and staged in Midgard, not yet shipped. Durable fix (shipped `.props`/`.targets` in `Abstractions.Contracts`, new Asgard version, republish, drop the Yggdrasil workarounds, confirm package-mode build) is scoped, not started — full detail: `../Glitnir/docs/Platform/plans/2026-07-24-transport-neutral-invocation-pipeline.md`.

**Resolved since last pass:** the `IDeferredSignIn` realm-placement question that used to sit here as item 2 is settled. Asgard's `Abstractions.Web.Server` now declares the contract (PR #28, merged); Midgard's `Infrastructure.Web.Server` implements it against Asgard instead of declaring its own (commit `590f208`, shipped via PR #29 — bundled alongside an unrelated interceptor-visibility fix, not a dedicated PR). The ship step also cleared (corrected 2026-07-25 — previously logged here as still pending): Himinbjörg's `feature/identity-web-server` branch merged via PR #27 and shipped in tag `v0.0.5`, with the full gRPC wireup done (`LoginHandler`/`RegisterHandler` drive `SignInManager`/`UserManager` for real against Heimdall's generated `IAuthenticationGateway`).
