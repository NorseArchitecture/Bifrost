# CLAUDE.md — Bifrost (Norse.Orchestration)

Cold-start context for any Claude Code session in this repo. Where a rule here conflicts with a default behavior, this file wins.

## 1. What This Repository Is

**Bifröst** is the local developer meta-repository for the Norse Architecture — the rainbow bridge between the realms. It exists for exactly one purpose: **clone once and run.** It composes every resource required to run and develop the platform — services, databases, queues, and configuration — via a .NET Aspire AppHost under the `Norse.Orchestration.*` namespace.

It is a **reference composition, not a product**. Consumers of the Norse Architecture are expected to build their own bridge: take the realm repos they need as submodules, write their own AppHost, and swap the runtime containers for whatever direction their platform is going. Contributions land in the realms; pull requests here should be rare — composition fixes, not features.

**Every Claude Code session starts from Bifröst.** The bridge is the working root: all realms are checked out beneath it, and **Glitnir** rides alongside as the design court — every spec, plan, and proof of concept that enters the record as part of a rendered verdict lives there. Realm CLAUDE.md files reference Glitnir documents by sibling-relative path (`../Glitnir/docs/...`).

**State of the union (2026-07-01):** the migrations framework — the first piece of runtime composition this repository exists to prove out — has landed end to end. Six realms shipped their slice in strict dependency order, each behind its own ship gate (PR merged, CI green, tagged, published to NuGet): Asgard declared `IMigrationContributor`, Midgard built the `MigrationRunnerService` runner, Urdarbrunnr shipped the EF foundation plus this platform's first Roslyn source generator, Himinbjörg proved it against the hardest brownfield case there is (full ASP.NET Core Identity v3 + OpenIddict), Yggdrasil's migrations service went from a placeholder stub to a permanent three-line `Program.cs`, and Bifröst wired a Postgres primary + streaming replica into the Aspire dashboard and pointed the migrations service at it. Run `dotnet run --project src/Orchestration.AppHost` today and `norse_identity` stands up for real. Full narrative: `../Glitnir/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md`. This is the template every future bounded context now follows to get its own `norse_{context}` database online.

**Peer repositories** sit beside Bifröst in the same parent directory and are not submodules of it:

| Repository | Local path | Purpose |
|---|---|---|
| Ginnungagap (`.github`) | `../.github` | The primordial void: org-default community-health files, reusable GitHub Actions workflows (`ci-build-test.yml`, `release-nuget.yml`, `update-bifrost.yml`), config scatter (`scatter-the-runes.ps1`, `manifest.psd1`), and the Law of the Æsir. Referenced by realms as `NorseArchitecture/.github/.github/workflows/*.yml@master`. |

## 2. The Naming Model

**Repositories are named for the lore; projects and namespaces are named for the function.** Open the org and you tour the cosmos; open the solution and every project says what it does. The codename never appears as an operational identifier — `Bifrost` is the repo name and the story, `Norse.Orchestration` is the code.

| Repository (lore) | Namespace (code) | Function |
|---|---|---|
| Svartalfheim | `Norse.Primitives.*` | The forge: `Result<T>`, the parsing stack, and the analyzers and BuildCheck rules that strike when law is broken |
| Asgard | `Norse.Abstractions.*` | Declared law: contracts, attribute model, plugin interfaces, mediator law |
| Midgard | `Norse.Infrastructure.*` | Embodied law: concrete persistence, mediator runtime, API, UI Composition framework |
| Urdarbrunnr | `Norse.EntityFramework.*` | Entity base types, DbContext foundations, conventions, value converters, and the migrations chassis |
| Ratatoskr | `Norse.NServiceBus.*` | NServiceBus endpoint configuration, saga infrastructure, message conventions, and transport wiring — the squirrel that carries messages between the realms |
| Yggdrasil | `Norse.Hosting.*` | Hosting runtimes and deployables: web server, worker, migration service, WASM client, and MAUI app |
| Himinbjörg | `Norse.Identity.*` | EF persistence for ASP.NET Identity and OpenIddict: entities, conventions, and migrations; sealed server-side, never referenced from WASM or MAUI |
| Heimdall | `Norse.Access.*` | Auth services on Himinbjörg: one access ruleset across Blazor Server, WASM, and MAUI, with admin Blazor components and the backing gRPC service |
| Naglfar | `Norse.DesignSystem.*` | Design tokens, radii, and component primitives — standalone for now, no declared consumers |
| Glitnir | — (documents only) | Design court: specs, plans, and proof-of-concept verdicts |
| **Bifröst** (this repo) | `Norse.Orchestration.*` | Aspire AppHost composing the local development environment |
| Ginnungagap (`.github`) | — (org-defaults only) | The primordial void: community-health files, reusable workflows, config scatter, and the Law of the Æsir — everything that exists before and beneath the realms |

**The brand prefix is build-injected, never file-encoded.** Project folders and `.csproj` files are brand-free (`src/Primitives/Primitives.csproj`); each realm's root `Directory.Build.props` injects `Norse.$(MSBuildProjectName)` as both `AssemblyName` and `RootNamespace`. A fork rebrands by changing `Norse` once per realm — no project renames, no slnx surgery; `namespace Norse.*` declarations in code do not follow (that's the fork's own act). Solution folders in `Bifrost.slnx` carry the function names (`/Primitives/`), one per realm.

**Aspire ecosystem names are kept, not fought:** the AppHost project keeps its Aspire-conventional shape — project `Orchestration.AppHost`, assembly `Norse.Orchestration.AppHost`. Don't invent novel names for things the ecosystem has already named.

## 3. Submodules

Each platform realm is a git submodule. Two non-negotiable conventions:

- **Relative URLs** (`../Svartalfheim.git`), resolved against whatever remote Bifrost was cloned from — one `.gitmodules` serves HTTPS and SSH clones identically. A fork of Bifrost resolves submodules against the fork's owner and fails loudly unless the realms are forked alongside it. **That behavior is deliberate** — forking the bridge is the signal to build your own, not a workflow we accommodate.
- **Branch tracking on `master`** (`-b master` in `.gitmodules`). `git submodule update --remote` pulls each realm's tip; this repo exists for developer productivity, so tracking beats SHA-pinning here.

New realm lands? `git submodule add -b master ../{Realm}.git` and update the realm tables in both README.md and this file in the same change.

## 4. What Belongs Here (and What Doesn't)

**Belongs here:**

- `Orchestration.AppHost` (assembly `Norse.Orchestration.AppHost`) — the Aspire AppHost and its container/resource profile for the local environment.
- `.gitmodules`, the realm submodules, and repo-level build plumbing shared across the composition.

**Does not belong here:**

- **Runtime endpoints, hosting chassis, service code** — that's Yggdrasil (`Norse.Hosting.*`) and below. Bifrost composes what the realms provide; it never provides.
- **`ServiceDefaults`** — ruled 2026-06-28: Midgard (`Norse.Infrastructure.*`); never Yggdrasil, never Bifröst, Aspire convention notwithstanding.
- **Anything a specific company or product needs** — product code is sovereign and lives under its own root, in its own repos, on its own bridge.

When in doubt: if deleting Bifröst would break anything other than the local dev experience, the thing is in the wrong repo.

## 5. Conventions

Code style, indentation, `var`, accessibility, and naming rules: global `~/.claude/CLAUDE.md`. Bifrost-specific additions:

- **`.slnx` solution format** (`dotnet new sln --format slnx`); project layout `src/{ProjectName}/{ProjectName}.csproj` with brand-free project names (see §2). Each realm's solution file is named for the lore (`Svartalfheim.slnx`), matching its repo.
- **`sealed` by default** — `internal sealed` is the default for every new type; open only when a concrete subtype exists.
- **Relative paths only in documents** (hard law, 2026-06-11): repo-relative or workspace-relative (`../Glitnir/docs/...`); machine-local absolute paths never enter the record — environment variables name machine locations when unavoidable.

## 6. Process

- **No automatic git commits.** Stage and show the diff; the human commits. When in doubt, stop and wait.
- **No force-pushing to `master`.** No skipping git hooks. No committing secrets — local dev configuration uses user secrets or Aspire-managed values, never checked-in credentials.
- **Implementation is subagent-driven and test-driven, always.** `superpowers:subagent-driven-development` is the default — `executing-plans` is the narrow separate-session fallback, never interchangeable. Pairs with `superpowers:test-driven-development` on every coding task. Full rule: `../Glitnir/CLAUDE.md` §2.8.
- **README.md and CLAUDE.md stay in sync — boy-scout law.** The pair tells one story at two altitudes: README is the public narrative, CLAUDE.md the working law. Any change touching what either describes — submodules, naming, conventions, composition — updates both in the same change, and the realm tables in both files must match `.gitmodules` exactly. Touch a repo, check its pair before you leave.

## 7. CI/CD Patterns

Coverage CI and release pipeline proven on Svartalfheim (PRs #4, #6). Full design and gotchas: `../Glitnir/docs/Platform/specs/2026-06-26-code-coverage-ci-design.md`.

**Realm adoption — two files:**

1. `tests/Directory.Build.props` — `<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="18.*" />` (hoisted; alphabetical order).
2. `.github/workflows/ci.yml` — `permissions: pull-requests: write` at workflow level; `with: minimum_coverage: <N>` on the `gate` job.

**Non-obvious bits:**
- **`18.*` only** — `17.*` fails at MTP 2.x startup with `MissingMethodException`. No `17.x` works.
- **No `.runsettings`** — silently ignored by MTP; `git rm` any that exist.
- **Coverage floor is 60** in the shared workflow; `minimum_coverage` input default is `0`. Effective = `max(60, input)`.

## 8. Open Decisions

Raise these before writing code that touches them; do not silently proceed:

1. **Container profile composition — Postgres decided and live; broker, cache, and any further identity-provider containers still open.** The dashboard-first goal cleared its first milestone: Postgres primary+replica is wired into the Aspire dashboard (`src/Orchestration.AppHost/AppHost.cs`), and the migrations service — the first real runtime endpoint Yggdrasil hosts — runs to completion against it, standing up `norse_identity` with the full ASP.NET Core Identity v3 + OpenIddict schema. Full design and rollout: `../Glitnir/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md`. Still open: broker and cache containers, any additional identity-provider containers, and how a consumer swapping them out is expected to express that.
