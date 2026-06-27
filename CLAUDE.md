# CLAUDE.md — Bifrost (Norse.Orchestration)

Cold-start context for any Claude Code session in this repo. Where a rule here conflicts with a default behavior, this file wins.

## 1. What This Repository Is

**Bifrost** is the local developer meta-repository for the Norse Architecture — the rainbow bridge between the realms. It exists for exactly one purpose: **clone once and run.** It composes every resource required to run and develop the platform — services, databases, queues, and configuration — via a .NET Aspire AppHost under the `Norse.Orchestration.*` namespace.

It is a **reference composition, not a product**. Consumers of the Norse Architecture are expected to build their own bridge: take the realm repos they need as submodules, write their own AppHost, and swap the runtime containers for whatever direction their platform is going. Contributions land in the realms; pull requests here should be rare — composition fixes, not features.

**Every Claude Code session starts from Bifrost.** The bridge is the working root: all realms are checked out beneath it, and **Glitnir** rides alongside as the design court — every spec, plan, and proof of concept that enters the record as part of a rendered verdict lives there. Realm CLAUDE.md files reference Glitnir documents by sibling-relative path (`../Glitnir/docs/...`).

**Peer repositories** sit beside Bifrost in the same parent directory and are not submodules of it:

| Repository | Local path | Purpose |
|---|---|---|
| `.github` | `../.github` | Org-default community-health files and shared reusable GitHub Actions workflows (`ci-build-test.yml`, `release-nuget.yml`, `update-bifrost.yml`). Referenced by realms as `NorseArchitecture/.github/.github/workflows/*.yml@master`. |

## 2. The Naming Model

**Repositories are named for the lore; projects and namespaces are named for the function.** Open the org and you tour the cosmos; open the solution and every project says what it does. The codename never appears as an operational identifier — `Bifrost` is the repo name and the story, `Norse.Orchestration` is the code.

| Repository (lore) | Namespace (code) | Function |
|---|---|---|
| Svartalfheim | `Norse.Primitives.*` | Domain value types, identifiers, result parsing, encryption |
| Asgard | `Norse.Abstractions.*` | Contracts and laws every realm must honor |
| Midgard | `Norse.Infrastructure.*` | Concrete implementations: persistence, caching, integrations |
| Urdarbrunnr | `Norse.EntityFramework.*` | Entity base types, DbContext foundations, conventions, value converters, migrations chassis |
| Ratatoskr | `Norse.NServiceBus.*` | NServiceBus endpoint configuration, saga infrastructure, message conventions, and transport wiring — the squirrel that carries messages between the realms |
| Yggdrasil | `Norse.Hosting.*` | Web, worker, and migration service chassis |
| Himinbjorg | `Norse.Identity.*` | EF persistence for ASP.NET Identity + OpenIddict — backend-only entities, conventions, and migrations; never referenced from WASM or MAUI |
| Heimdall | `Norse.Access.*` | Auth services on Himinbjorg: one access ruleset across Blazor Server, WASM, and MAUI, plus admin Blazor components and the backing gRPC service |
| Nagalfar | `Norse.DesignSystem.*` | Design tokens, radii, and component primitives — standalone for now, no declared consumers |
| Glitnir | — (documents only) | Design court: specs, plans, and proof-of-concept verdicts |
| **Bifrost** (this repo) | `Norse.Orchestration.*` | Aspire AppHost composing the local development environment |

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
- **`ServiceDefaults`** — ruled 2026-06-11: Midgard (`Norse.Infrastructure.*`) if possible; Yggdrasil (`Norse.Hosting.*`) only if it carries shared runtime context that touches all the composition runtimes; never Bifrost, Aspire convention notwithstanding.
- **Anything a specific company or product needs** — product code is sovereign and lives under its own root, in its own repos, on its own bridge.

When in doubt: if deleting Bifrost would break anything other than the local dev experience, the thing is in the wrong repo.

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

1. **Container profile composition.** Which resources the local profile stands up (database, broker, cache, identity), and how consumers swapping containers are expected to express that, is being designed dashboard-first: the immediate goal is the full local environment wired cleanly into the Aspire dashboard **before any runtime endpoint exists in Yggdrasil**.
