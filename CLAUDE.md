# CLAUDE.md — Bifröst (Norse.Orchestration)

Cold-start context for any Claude Code session in this repo. Where a rule here conflicts with a default behavior, this file wins.

## 1. What This Repository Is

**Bifröst** is the local developer meta-repository for the Norse Architecture — the rainbow bridge between the realms. It exists for exactly one purpose: **clone once and run.** It composes every resource required to run and develop the platform — services, databases, queues, and configuration — via a .NET Aspire AppHost under the `Norse.Orchestration.*` namespace.

It is a **reference composition, not a product**. Consumers of the Norse Architecture are expected to build their own bridge: take the realm repos they need as submodules, write their own AppHost, and swap the runtime containers for whatever direction their platform is going. Contributions land in the realms; pull requests here should be rare — composition fixes, not features.

**Every Claude Code session starts from Bifröst.** The bridge is the working root: all realms are checked out beneath it, and **Glitnir** rides alongside as the design court — every spec, plan, and proof of concept that enters the record as part of a rendered verdict lives there. Realm CLAUDE.md files reference Glitnir documents by sibling-relative path (`../Glitnir/docs/...`).

**State of the union (2026-07-01):** the migrations framework — the first piece of runtime composition this repository exists to prove out — has landed end to end. Six realms shipped their slice in strict dependency order, each behind its own ship gate (PR merged, CI green, tagged, published to NuGet): Asgard declared `IMigrationContributor`, Midgard built the `MigrationRunnerService` runner, Urðarbrunnr shipped the EF foundation plus this platform's first Roslyn source generator, Himinbjörg proved it against the hardest brownfield case there is (full ASP.NET Core Identity v3 + OpenIddict), Yggdrasil's migrations service went from a placeholder stub to a permanent three-line `Program.cs`, and Bifröst wired a Postgres primary + streaming replica into the Aspire dashboard and pointed the migrations service at it. Run `dotnet run --project src/Orchestration.AppHost` today and `norse_identity` stands up for real. Full narrative: `../Glitnir/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md`. This is the template every future bounded context now follows to get its own `norse_{context}` database online — Mímisbrunnr already proved it days later, standing up `norse_reference` with zero new framework code.

**State of the union (2026-07-25):** the transport-neutral invocation pipeline first landed behind generator-composed gateways. Asgard shipped `Outcome<T>` (`Abstractions.Contracts`, the platform's second discriminated union) and the `GatewayGenerator` (`Contract`/`InProcessHost`/`WireHost` emission from `[GenerateGateway]`); Yggdrasil's Task 13/14 turned `InProcessHost` mode on for the first time anywhere on the platform (PR #36, Asgard tag v0.0.10). That shape is superseded two days later — see the 2026-07-27 entry below. **Correction:** the four-stage mediator pipeline was never built over `martinothamar/Mediator`; no `.csproj` on the platform ever referenced it, and the claim otherwise (repeated across six documents at the time) was traced to its source and fixed in the same pass — the dispatch chain was hand-rolled from day one. Doctrine for the platform's two discriminated unions (`Result<T>` vs `Outcome<T>`, why they rhyme and why they're never siblings) is recorded at `../Glitnir/docs/the-two-unions.md`.

**State of the union (2026-07-27):** the transport-neutral pipeline reached its final shape, subtracting the gateway machinery a same-day code audit found mostly dead on arrival — `OutcomeServerInterceptor` implemented and unit-tested but never registered, both generated gateways carrying zero test coverage, and the WASM wire path reaching handlers with no server-side validation or authorization at all. Asgard now declares `IRequest<T>`/`ICommandRequest<T>`/`IQueryRequest<T>` and `ISender` in `Abstractions.Web.Server.Mediator` — deliberately server-only, so wire `[DataContract]` records carry no mediator coupling and stay lean for WASM. Midgard composes the chain once, in DI, around the handlers (`AddNorsePipeline()` + a hand-rolled `Sender` folding `IEnumerable<IBehavior<,>>` — no MediatR, no martinothamar/Mediator, no package underneath at all), ships the registration generator plus the gRPC server/client wiring generators, and finally registers `OutcomeServerInterceptor`. Yggdrasil adopted the generated wiring, deleted both `CompilerVisibleProperty` workarounds and both generated gateways, and enabled gRPC-Web. Components now inject `I{Context}Service` directly — `IAuthenticationGateway` is deleted. Full narrative: `../Glitnir/docs/Platform/specs/2026-07-27-mediator-pipeline-retires-gateway-design.md`.

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
- **Generator emitters never call `AppendLine` directly.** Always `sb.AppendCSharp(...)` (`Norse.Abstractions.Emit.CSharpEmit`, a `[StringSyntax("C#")]`-annotated `AppendLine` wrapper) — including single-line appends. What would otherwise be multiple sequential `AppendLine` calls collapses into one `AppendCSharp` call with a raw string literal (`"""..."""`), so the generated shape reads as a block instead of being reconstructed line-by-line at the call site. Design: `../Glitnir/docs/Asgard/specs/2026-07-25-generator-authoring-toolkit-and-raw-string-house-style-design.md`.

## 6. Operating Modes

Every session runs in one of three modes. Wall clock is the metric: ceremony nobody asked for — git-status narration, unsolicited commit/PR offers, reflexive skill invocation, "here's what I changed" epilogues — is waste, not diligence. A dirty working tree is the expected steady state, not an anomaly; Buvy is routinely curating the same tree in parallel. Never flag, stash, warn about, or narrate uncommitted changes unless they're directly implicated in the task at hand.

**Mode 1 — Debugging.** `superpowers:systematic-debugging`, or the session is plainly "fix this broken thing." Fix the issue at hand; that is the entire scope. Pending changes elsewhere in the tree are invisible — don't mention them, don't treat them as suspicious. Exception: if the pending changes are the root cause, fix them (still fixing the issue) without editorializing about the dirty state. No opportunistic "while I was in here" cleanup.

**Mode 2 — Cleanup/chore/curation.** Doc sweeps, renames, stale-data fixes, pragma removal, and similar mechanical work. Do the item asked for and nothing else. **No skill invocation** — none are needed for chore work; this overrides the reflexive skill-check default for this mode specifically. No git-state checks — in-flight changes are expected. No extra builds. No commit/PR offers or commit-message summaries. The only verification gate: the touched project's tests still pass. Run them, confirm green, then stop per §7's handoff — stage the diff, no narration, the human commits.

**Mode 3 — Feature pipeline.** `superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:subagent-driven-development`. `writing-plans` always reads `Glitnir/docs/house-rules.md` first and always plans for TDD — tests first, structurally, not as an option. `subagent-driven-development` forks the next task the moment the current one reaches review, but never gets more than one task ahead of review, so a requested change stays small-blast-radius; on a genuine implementation wall, halt and ask — never improvise around it, never guess, never "make progress elsewhere" while blocked. Every stage transition (brainstorm → plan, plan → code) is a human gate, never inferred from momentum or a prior session. The sole exception is permission stated explicitly and in advance for unattended continuation ("finish this off while I sleep") — never assumed.

## 7. Process

- **NEVER branch Bifröst itself.** Stay on `master` — near-absolute, not a default-with-exceptions. The one narrow exception requires both: (1) the feature genuinely lives in Bifröst's own tracked files (`Orchestration.AppHost`, `Bifrost.slnx`, `.gitmodules`, root build plumbing), not a submodule pointer bump; and (2) every other realm submodule is on `master`, nothing else in flight. If either fails, stay on `master`. `master` absorbs constant bot traffic (CPM bumps, config scatter, release fan-in, submodule pointer updates) that a feature branch would have to carry and reconcile against — expensive and painful in a way an isolated realm repo isn't.
- **No automatic git commits.** Stage and show the diff; the human commits. When in doubt, stop and wait.
- **No force-pushing to `master`.** No skipping git hooks. No committing secrets — local dev configuration uses user secrets or Aspire-managed values, never checked-in credentials.
- **Implementation is subagent-driven and test-driven, always.** `superpowers:subagent-driven-development` is the default — `executing-plans` is the narrow separate-session fallback, never interchangeable. Pairs with `superpowers:test-driven-development` on every coding task. Full rule: `../Glitnir/CLAUDE.md` §2.8.
- **README.md and CLAUDE.md stay in sync — boy-scout law.** The pair tells one story at two altitudes: README is the public narrative, CLAUDE.md the working law. Any change touching what either describes — submodules, naming, conventions, composition — updates both in the same change, and the realm tables in both files must match `.gitmodules` exactly. Touch a repo, check its pair before you leave.

## 8. CI/CD Patterns

Coverage CI and release pipeline proven on Svartálfheim (PRs #4, #6). Full design and gotchas: `../Glitnir/docs/Platform/specs/2026-06-26-code-coverage-ci-design.md`.

**Realm adoption — two files:**

1. `tests/Directory.Build.props` — `<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="18.*" />` (hoisted; alphabetical order).
2. `.github/workflows/ci.yml` — `permissions: pull-requests: write` at workflow level; `with: minimum_coverage: <N>` on the `gate` job.

**Non-obvious bits:**
- **`18.*` only** — `17.*` fails at MTP 2.x startup with `MissingMethodException`. No `17.x` works.
- **No `.runsettings`** — silently ignored by MTP; `git rm` any that exist.
- **Coverage floor is 0.1** in the shared workflow (`FLOOR=0.1` in `ci-build-test.yml`, temporarily lowered until the ASP.NET Identity template is out of Yggdrasil — see Ginnungagap's `CLAUDE.md`); `minimum_coverage` input default is `0`. Effective = `max(0.1, input)`. Corrected 2026-07-25 — previously logged here as 60, which the workflow source does not support.

## 9. Open Decisions

Raise these before writing code that touches them; do not silently proceed:

1. **Container profile composition — Postgres decided and live; broker, cache, and any further identity-provider containers still open.** The dashboard-first goal cleared its first milestone: Postgres primary+replica is wired into the Aspire dashboard (`src/Orchestration.AppHost/AppHost.cs`), and the migrations service — the first real runtime endpoint Yggdrasil hosts — runs to completion against it, standing up `norse_identity` with the full ASP.NET Core Identity v3 + OpenIddict schema. Full design and rollout: `../Glitnir/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md`. Still open: broker and cache containers, any additional identity-provider containers, and how a consumer swapping them out is expected to express that.

**Resolved since last pass:** the `IDeferredSignIn` realm-placement question that used to sit here as item 2 is settled. Asgard's `Abstractions.Web.Server` now declares the contract (PR #28, merged); Midgard's `Infrastructure.Web.Server` implements it against Asgard instead of declaring its own (commit `590f208`, shipped via PR #29 — bundled alongside an unrelated interceptor-visibility fix, not a dedicated PR). The ship step also cleared (corrected 2026-07-25 — previously logged here as still pending): Himinbjörg's `feature/identity-web-server` branch merged via PR #27 and shipped in tag `v0.0.5`, with the full gRPC wireup done (`LoginHandler`/`RegisterHandler` drive `SignInManager`/`UserManager` for real against Heimdall's identity gateway). **Open Decision #2** (Asgard's `GatewayGenerator` unable to see `NorseGatewayEmissionMode`, plus the `InternalsVisibleTo` grant Midgard's four mediator `Behavior` classes needed) **dissolves outright as of 2026-07-27** — the gateway generator, `NorseGatewayEmissionMode`, and the `InternalsVisibleTo` grant it required are all deleted, not fixed; the property the bug depended on no longer exists. The mediator pipeline that replaces it composes in DI around the handlers, with all four behaviors as plain DI citizens — no cross-assembly construction workaround needed. Full narrative: `../Glitnir/docs/Platform/specs/2026-07-27-mediator-pipeline-retires-gateway-design.md`.
