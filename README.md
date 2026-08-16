# Bifröst

> The rainbow bridge between the realms, watched over by Heimdall.

<p align="center">
  <img src="https://github.com/user-attachments/assets/ef2ba252-9011-4aec-a08e-a8434e16a43f" alt="Bifröst — the shimmering rainbow bridge spanning the nine realms, the only passage between worlds" title="Bifröst — the rainbow bridge between the realms" />
</p>

*Image credit: [@norsemythologyclips](https://www.instagram.com/norsemythologyclips/) — go follow them.*

The local developer meta-repository for the Norse platform — `Norse.Orchestration.*`, the .NET Aspire AppHost that composes every resource required to run and develop the platform: services, databases, queues, and configuration. Clone once, cross the bridge, and every realm grown on Yggdrasil is running.

## What's live: the migrations framework

Six realms, one dependency order, zero shortcuts. The first piece of runtime composition Bifröst exists to prove — a real service, wired into the Aspire dashboard, doing real work against a real database — landed end to end:

- **Asgard** declared `IMigrationContributor` — no `Order`, no `DependsOn`, because contributors are physically incapable of seeing each other's data.
- **Midgard** built `MigrationRunnerService`, the hosted service that runs every contributor and exits clean — or throws loud and hard, no swallowed exceptions.
- **Urðarbrunnr** shipped the EF foundation and this platform's first Roslyn source generator: it discovers every contributor at compile time and emits `AddNorseMigrations()`, proven identical whether contributors arrive as `ProjectReference` (this repo, today) or `PackageReference` (NuGet, tomorrow).
- **Himinbjörg** proved it against the hardest brownfield case there is: the full ASP.NET Core Identity v3 + OpenIddict schema, entities and all, landing in a real `norse_identity` Postgres database.
- **Yggdrasil**'s migrations service went from a `Placeholder.cs` stub to a three-line `Program.cs` that never has to change again, no matter how many bounded contexts join the platform.
- **Bifröst** wired a Postgres primary + streaming replica into the Aspire dashboard and pointed the migrations service at it.

Run it: `dotnet run --project src/Orchestration.AppHost`, watch `migrations` clear the dashboard green, then check `norse_identity` — the schema is real, not a sketch. Full design and task-by-task ship log: [Glitnir's migrations framework plan](https://github.com/NorseArchitecture/Glitnir/blob/master/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md).

**Where this is headed:** identity was the proving vehicle, not the destination. The same six-step relay — contract in Asgard, runner in Midgard, EF chassis in Urðarbrunnr, schema in the owning realm, wiring in Yggdrasil, composition in Bifröst — is now the template every future bounded context follows to get its own `norse_{context}` database online — Mímisbrunnr already rode it days later to stand up `norse_reference`, no new framework code required. Broker and cache containers are next in the open decisions queue.

## What's live: the mediator pipeline

The transport-neutral invocation pipeline landed in two passes. The first (2026-07-25) proved the envelope and wire encoding behind generator-composed gateways; a same-day code audit two days later found most of that generator machinery dead on arrival — an interceptor that was implemented, tested, and never registered, generated gateways with zero test coverage, and a WASM wire path that reached handlers with no server-side validation or authorization at all. The second pass (2026-07-27) subtracted it: Midgard now composes the chain once, in DI, around the handlers — `AddNorsePipeline()` plus a hand-rolled `Sender` folding `IBehavior<,>` instances, no MediatR, no martinothamar/Mediator, no package underneath it at all (a claim six documents made at the time, none of them accurate). Every channel — Blazor Server circuit and gRPC wire alike — now runs through the same four behaviors, so the wire path finally gets the validation and authorization the gateway design promised but never wired. Components inject `I{Context}Service` directly; `IAuthenticationGateway` is gone. Full verdict: [Glitnir's mediator-pipeline design](https://github.com/NorseArchitecture/Glitnir/blob/master/docs/Platform/specs/2026-07-27-mediator-pipeline-retires-gateway-design.md).

## What's live: flip one property, get two platforms

Every cross-realm reference on the bridge is declared once, as a `NorseRef` item, and resolved by a single MSBuild property: `UseProjectReferences`. Flip it to `true` and the whole stack builds from source across every submodule on disk — edit Svartálfheim, rebuild Mímisbrunnr, the change is just *there*, no publish, no version bump, no wait. Flip it to `false` and the same declaration resolves to the exact NuGet packages GitHub Actions resolves — the same dependency graph, the other lens, on the same machine, in the time it takes to rebuild. A checkout with no Bifröst ancestor on disk — a genuinely standalone realm clone — falls back to that same package crossing by construction: there's no secret third mode hiding behind "standalone."

That one toggle is what makes a stale `master` pointer in this repository harmless: shipping software never reads Bifröst's checkout, it reads what each realm actually published, so submodule drift here can't leak into a release. It's also what makes a CI-only failure locally reproducible in one rebuild instead of a fresh pipeline run, and what keeps the realms honestly independent: every realm publishes its own versioned NuGet package on its own ship gate — PR merged, CI green, tag pushed, `dotnet pack`, GitHub release published — with no hidden coupling between what's on disk here and what's actually shipped. Full doctrine, including the analyzer/generator delivery rules and the DacFx template family this same toggle now governs: [Glitnir's `the-runes.md`](https://github.com/NorseArchitecture/Glitnir/blob/master/docs/the-runes.md).

## The realms on the bridge

Each realm is a git submodule, pinned to track `master`. Repositories carry the lore; namespaces carry the function:

| Submodule | The function |
|---|---|
| [Svartálfheim](https://github.com/NorseArchitecture/Svartalfheim) | `Norse.Primitives.*` — the forge: `Result<T>`, the parsing stack, and the analyzers and BuildCheck rules that strike when law is broken |
| [Asgard](https://github.com/NorseArchitecture/Asgard) | `Norse.Abstractions.*` — declared law: contracts, attribute model, plugin interfaces, mediator law |
| [Midgard](https://github.com/NorseArchitecture/Midgard) | `Norse.Infrastructure.*` — embodied law: concrete persistence, mediator runtime, API, UI Composition framework |
| [Urðarbrunnr](https://github.com/NorseArchitecture/Urdarbrunnr) | `Norse.Persistence.*` — the persistence realm: any database or data-store mechanism, not just EF Core. `Norse.Persistence.EntityFramework.*` is the live vendor family — entity base types, DbContext foundations, conventions, value converters, and the migrations chassis; other ORMs, native drivers, or document/search stores land as their own sibling |
| [Ratatoskr](https://github.com/NorseArchitecture/Ratatoskr) | `Norse.Messaging.*` — the messaging realm; `Norse.Messaging.NServiceBus.*` (endpoint configuration, saga infrastructure, message conventions, transport wiring) is the live vendor family; the squirrel that carries messages between the realms |
| [Yggdrasil](https://github.com/NorseArchitecture/Yggdrasil) | `Norse.Hosting.*` — hosting runtimes and deployables: web server, worker, migration service, WASM client, MAUI app, and the BlazingStory catalog host (`Hosting.Stories.Client`/`.Server`) |
| [Himinbjörg](https://github.com/NorseArchitecture/Himinbjorg) | `Norse.Identity.*` — EF persistence for ASP.NET Identity and OpenIddict: entities, conventions, and migrations; sealed server-side, never referenced from WASM or MAUI |
| [Heimdall](https://github.com/NorseArchitecture/Heimdall) | `Norse.AuthN.*` — the authn story on Himinbjörg's identity record: login, register, forgot-password, 2FA setup, recovery, and reset, uniform across Blazor Server, WASM, and MAUI, with the backing gRPC service |
| [Mímisbrunnr](https://github.com/NorseArchitecture/Mimisbrunnr) | `Norse.Reference.Data.*` — entities, view models, TSV seeders (nietras Sep), and migrations for canonical reference data: ISO country/currency codes, IANA time zones — and now also where the generated `Reference.Data.Primitives`/`.Namespaces` surface (`IsoCountryCode`, `Iso3166`, `ReferenceNamespaces`) lives |
| [Mímir](https://github.com/NorseArchitecture/Mimir) | `Norse.Reference.Components` / `.Web.Server` / `.Worker` — the serving layer on Mímisbrunnr: Blazor components, gRPC service host, and the background worker that keeps reference data current — consumes Mímisbrunnr's generated surface by reference, generates nothing itself |
| [Naglfar](https://github.com/NorseArchitecture/Naglfar) | `Norse.DesignSystem.*` — the token pipeline (`@norsearchitecture/design-tokens`, Style Dictionary), assembled from the unglamorous remnants into something seaworthy enough to carry every product UI. npm-first — one 100%-generated .NET package (`DesignSystem.Tokens`), no hand-authored C# |
| [Bragi](https://github.com/NorseArchitecture/Bragi) | `Norse.DesignSystem.Stories` — the content-only Razor Class Library of `.stories.razor` catalog pages that Yggdrasil's BlazingStory host serves; split out of Naglfar 2026-07-12 |
| [Vafthrudnir](https://github.com/NorseArchitecture/Vafthrudnir) | *(Bruno workspace only)* — the interrogator: git-native Bruno collections (OpenCollection YAML) testing every API surface — gRPC, REST, and a declared MCP fast-follow — currently interrogating Yggdrasil's hosted footprint; carries no logic of its own |
| [Glitnir](https://github.com/NorseArchitecture/Glitnir) | *(docs only)* — the design court: specs, plans, and proof-of-concept verdicts; every design is tried there before code is forged |

## The primordial void

[Ginnungagap](https://github.com/NorseArchitecture/.github) is not on the bridge — GitHub enforces the repository name `.github` and it carries no submodule. But it is the void beneath every realm: org-default community-health files, the reusable GitHub Actions workflows every realm calls, the config scatter that keeps them all in sync, and the Law of the Æsir carved into every branch. Nothing exists before it.

## The design court

[Glitnir](https://github.com/NorseArchitecture/Glitnir) rides the bridge at `./Glitnir` so the entire design record travels with the workspace. Every spec, plan, and proof-of-concept verdict lives there — the realms hold code, the court holds the record, and the Glitnir submodule pin in this repository is the verdict ledger. Start with its [README](https://github.com/NorseArchitecture/Glitnir#readme) for the platform thesis; its `CLAUDE.md` carries the session law.

## Getting started

Clone with submodules in one step — both protocols work identically:

```shell
# HTTPS
git clone --recurse-submodules https://github.com/NorseArchitecture/Bifrost.git

# SSH
git clone --recurse-submodules git@github.com:NorseArchitecture/Bifrost.git
```

Already cloned without them? `git submodule update --init --recursive`.

To pull each realm's latest `master` after the initial clone:

```shell
git submodule update --remote
```

### Devcontainer setup: host environment variables

`.devcontainer/devcontainer.json`'s `remoteEnv` block forwards `NUGET_AUTH_TOKEN`, `GIT_USER_NAME`, and `GIT_USER_EMAIL` in from the host — it never supplies them. Set all three in the host environment (whichever shell actually launches VS Code) *before* the container is created or rebuilt; `${localEnv:VAR}` resolves once, at that moment, so a value set afterward needs a rebuild to take effect.

**Get the NuGet token with the `gh` CLI.** A classic PAT works too, but if you're already signed in with `gh` this is the shortest path — it needs `read:packages` scope and NorseArchitecture org access:

```shell
gh auth login                                  # skip if already logged in
gh auth refresh -h github.com -s read:packages # add the scope to the existing session
gh auth token                                  # prints the token — this is your NUGET_AUTH_TOKEN
```

**Set the variables on the host**, persistently, in whichever shell launches VS Code:

```powershell
# Windows PowerShell — persists across sessions; open a new terminal (or restart VS Code) to pick it up
[Environment]::SetEnvironmentVariable('NUGET_AUTH_TOKEN', '<token from gh auth token>', 'User')
[Environment]::SetEnvironmentVariable('GIT_USER_NAME', '<your name>', 'User')
[Environment]::SetEnvironmentVariable('GIT_USER_EMAIL', '<your email>', 'User')
```

```shell
# macOS — zsh is the default shell since Catalina; `source ~/.zshrc` or open a new terminal afterward
echo 'export NUGET_AUTH_TOKEN="<token from gh auth token>"' >> ~/.zshrc
echo 'export GIT_USER_NAME="<your name>"' >> ~/.zshrc
echo 'export GIT_USER_EMAIL="<your email>"' >> ~/.zshrc
```

```shell
# bash / Linux (including WSL2) — `source ~/.bashrc` or open a new terminal afterward
echo 'export NUGET_AUTH_TOKEN="<token from gh auth token>"' >> ~/.bashrc
echo 'export GIT_USER_NAME="<your name>"' >> ~/.bashrc
echo 'export GIT_USER_EMAIL="<your email>"' >> ~/.bashrc
```

Don't put these in a script that runs *inside* the devcontainer, and don't put them in a repo-tracked file — they belong to the host shell that spawns VS Code, never the container and never git.

**SSH agent — required on every platform, set up differently on each.** `configure-git-ssh-signing.sh` runs once per container create/rebuild and calls `ssh-add -L` to find a signing key; if the forwarded agent is empty at that moment it silently skips signing setup rather than failing the build, which just means commits go unsigned until a key is loaded and the container is rebuilt. VS Code's Dev Containers extension forwards whatever agent is live on the host into the container's `SSH_AUTH_SOCK` automatically — the part that isn't automatic is making sure a real agent, holding your key, exists on the host in the first place:

- **Windows** — the native OpenSSH Agent Windows service. One-time enable, then load the key:
  ```powershell
  Get-Service ssh-agent | Set-Service -StartupType Automatic
  Start-Service ssh-agent
  ssh-add $env:USERPROFILE\.ssh\id_ed25519
  ```
- **macOS** — `ssh-agent` plus Keychain, so the key survives reboots without re-adding it by hand:
  ```shell
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  ```
- **bash / Linux (WSL2)** — WSL2 has no native bridge to a Windows agent, so either run an agent inside WSL and add the key there, or use an agent-forwarding bridge (e.g. Bitwarden's) — see `configure-git-ssh-signing.sh`'s own comments for the bridge this repo is set up against:
  ```shell
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  ```

Run `ssh-add -l` on the host right before opening or rebuilding the container to confirm a key is actually loaded — an empty agent is the single most common reason signing silently doesn't happen.

### Once the container is up: authenticate the CLIs

`docker-compose.yml` only persists `/home/vscode/.nuget`, `/home/vscode/.npm`, and the dev-certs store across rebuilds (see its `volumes:` list) — the rest of `/home/vscode`, including `gh`/`claude`/`codex`'s login state, is ephemeral container filesystem. Run this after every container create *and* every `Dev Containers: Rebuild Container`, not just the first time:

```shell
gh auth login   # GitHub CLI — interactive PR/issue use; separate from the NUGET_AUTH_TOKEN forwarded in from the host above
claude          # Claude Code — first run opens a browser-based login prompt
codex login     # OpenAI Codex CLI
```

While you're in there, pull in whatever Debian security/package patches have landed since the base image (`mcr.microsoft.com/devcontainers/base:debian`) was last built:

```shell
sudo apt update && sudo apt upgrade -y
```

### HTTPS dev certificate trust (WSL2 + Windows)

If you run `dotnet run`/`dotnet watch` inside WSL2 but browse from bare-metal Windows Chrome, `dotnet dev-certs https --trust` on either side is not enough — WSL2 and Windows each keep their own independent user cert store, so each OS generates and trusts its **own separate self-signed dev cert**. Running `--trust` (or even `--check`, which only reports "a valid certificate is already present" — a non-expired-cert check, not a trust check) on one side has zero effect on the other. Kestrel running inside WSL presents *its* cert; Windows Chrome only trusts *its own*, unrelated one — hence `net::ERR_CERT_AUTHORITY_INVALID` or resources getting blocked by SRI even after trusting "the" dev cert.

The documented fix is `dotnet dev-certs https --import` — sharing one cert across the boundary — but as of the .NET 11 preview SDK (`11.0.100-preview.5.26302.115`) that flag is broken: it fails identically on both WSL and Windows with a generic `Specify --help for a list of available options and commands.` parse error, regardless of password or quoting. Revisit `--import` once a later SDK drops; until then, do it by hand:

```shell
# In WSL — export the cert Kestrel actually presents, private key included
dotnet dev-certs https --export-path /mnt/c/Users/<you>/wsl-dev-cert.pfx -p <temp-password>
```

```powershell
# In Windows PowerShell — install that exact cert as trusted, bypassing the broken --import
$securePwd = ConvertTo-SecureString -String '<temp-password>' -AsPlainText -Force
$cert = Import-PfxCertificate -FilePath 'C:\Users\<you>\wsl-dev-cert.pfx' -CertStoreLocation Cert:\CurrentUser\My -Password $securePwd
$root = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root','CurrentUser')
$root.Open('ReadWrite'); $root.Add($cert); $root.Close()
```

Delete the `.pfx` from both sides afterward — it carries the private key. `dotnet dev-certs https --check` will still call this cert "Invalid" on the Windows side (`Import-PfxCertificate` marks the key non-exportable by default); that's the CLI's own bookkeeping opinion, not a browser trust problem — Chrome trusts it fine once it's in `CurrentUser\Root`.

### HTTPS dev cert trust (devcontainer + Windows)

Running inside `.devcontainer` instead of native WSL2 adds a third cert store to the mix — the container's own — but also removes the need for the PFX/password dance above. Windows only needs to trust the *public* cert to stop warning; it never needs the private key, since Kestrel inside the container holds that and never has to share it.

`postCreateCommand`'s `dev-cert-trust` step handles the container side automatically on every rebuild: it generates (or reuses) the dev cert, trusts it in-container, and exports the public half to `.devcontainer/certs/aspnetcore-dev.crt` (gitignored, regenerated per-machine — never commit it). The cert itself persists across rebuilds via the `norse-dotnet-certs` Docker volume, so its fingerprint stays stable — trust it once on Windows and it stays trusted through every future `devcontainer rebuild`, no re-import needed unless that volume itself is deleted.

The Windows side is the one step that can't be automated from inside the container — Windows' cert store is outside its authority. Run it once, ever, per machine:

```powershell
pwsh scripts/Trust-DevCert.ps1
```

After that, `https://localhost:5000` (the AppHost dashboard) and every other Aspire-forwarded port load without a browser warning.

Internal AppHost-to-AppHost traffic (the dashboard's own calls to its OTLP/resource-service endpoints) sidesteps cert trust entirely — `src/Orchestration.AppHost/Properties/launchSettings.json` points those two at `http://`, not `https://`, since it's loopback-only traffic with no real adversary and Linux chain validation of the raw ASP.NET Core dev cert (a leaf cert without `CA:TRUE`) is unreliable regardless of what's in `/etc/ssl/certs` — the `dev-cert-trust` step's `update-ca-certificates` call is best-effort for other in-container HTTPS callers, not load-bearing for the AppHost itself.

### Browser automation (Playwright MCP)

`.mcp.json` registers the [Playwright MCP server](https://github.com/microsoft/playwright-mcp), letting Claude Code drive a real headless Chromium against any of Bifröst's localhost sites — the AppHost dashboard, Yggdrasil's web/stories hosts — instead of guessing at what a page renders. `postCreateCommand`'s `playwright-browser` step provisions it automatically: OS-level native libs via `playwright install-deps` (root, can't be baked into the Dockerfile — that stage runs before the `node` feature layers on), then the Chromium binary itself as the `vscode` user. The `norse-playwright-browsers` Docker volume persists the ~300MB browser download across rebuilds, same pattern as the nuget/npm/dev-cert caches above.

No devcontainer Feature exists for this yet ([microsoft/playwright#33610](https://github.com/microsoft/playwright/issues/33610) is still open) — this is scripted install, not a feature, until one ships.

## Staying current

Clone it once, then leave it for a month — run these two scripts to get back to a known-good state:

```shell
# Pull every realm to master tip in parallel (no detached HEAD), then pull Bifrost itself
pwsh scripts/sync-the-realms.ps1

# Refresh every Docker image already in the local cache
pwsh scripts/pull-the-images.ps1
```

`sync-the-realms.ps1` fetches and fast-forwards each submodule concurrently, keeps them on a real branch, and exits non-zero if any realm fails. `pull-the-images.ps1` iterates the images already known to Docker — it refreshes, not discovers, so run it after the Aspire AppHost has been launched at least once.

## Developer tooling

None of the following install themselves — `dotnet restore` only touches package graphs. Each entry below is a one-time machine setup: `dotnet workload install {id}` for workloads, `dotnet new install {package}` for templates.

### Workloads

Workloads install SDK components — build targets, platform SDKs, and bundled templates — that ship outside the core .NET SDK. **MAUI workloads require Windows or macOS** — WSL2/Linux refuses them because the target platforms (Android, iOS, Mac Catalyst, Windows) are unavailable there.

| Workload | Templates | Why |
|---|---|---|
| `maui` | `maui`, `maui-blazor`, `mauilib`, `maui-page-*`, `maui-view-*`, `maui-dict-xaml` | Installs the MAUI SDK and build targets for Yggdrasil's MAUI app host. |

### Templates

| Package | Templates | Why |
|---|---|---|
| `Microsoft.Extensions.AI.Templates` | `aichatweb` | Scaffolds an AI chat web app wired to Microsoft.Extensions.AI with Blazor and Aspire. Starting point for design-system-hosted AI surfaces, once a component-library realm exists to host them. |
| `Blazorise.Templates` | `blazorise` | Scaffolds a Blazorise app. **Pending design team decision on whether Blazorise is the component library of record** — Naglfar is npm-first (one 100%-generated .NET exception, `DesignSystem.Tokens` — irrelevant to this decision, it's just token/CSS output), so this still has no obvious realm to land in; Bragi hosts story *content* only, not component implementations. |
| `Microsoft.FluentUI.AspNetCore.Templates` | `fluentblazor`, `fluentblazorwasm`, `fluentaspire-starter`, `fluentmaui-blazor-web` | Scaffolds Microsoft Fluent UI Blazor apps across server, WASM, Aspire, and MAUI-Blazor-hybrid variants. Same open question as Blazorise above — **pending design team decision on whether Fluent UI is the component library of record**, and which realm hosts it. |
| `BlazingStory.ProjectTemplates` | `blazingstoryserver`, `blazingstorywasm`, `bstories` | Scaffolds a Storybook-style catalog app for Blazor components, plus individual story files. This is the shape Bragi (`Norse.DesignSystem.Stories`) and Yggdrasil's `Hosting.Stories.Client`/`.Server` were split out of — see `../Glitnir/docs/Platform/specs/2026-07-12-designsystem-stories-hosting-design.md`. |
| `xunit.v3.templates` | `xunit3`, `xunit3-extension` | Creates correctly wired xUnit v3 test projects on Microsoft.Testing.Platform. The built-in `xunit` template installs v2 packages and produces projects that fail at MTP startup with `MissingMethodException`. |
| `ParticularTemplates` | `nsbendpoint`, `nsbhandler`, `nsbsaga` | Official NServiceBus scaffolding from Particular Software — endpoint, message handler, and saga stubs wired to NServiceBus conventions. Ratatoskr (`Norse.Messaging.NServiceBus.*`) is the realm that consumes these. |
| `Aspire.ProjectTemplates` | `aspire-apphost`, `aspire-servicedefaults`, and others | Official Aspire scaffolding. `aspire-apphost` is the template for new bridge AppHost projects; `aspire-servicedefaults` scaffolds the service-defaults project the platform intentionally places in Midgard (`Norse.Infrastructure.*`) rather than the AppHost. The starter and test templates (`aspire-starter`, `aspire-xunit`, etc.) are bundled but unused here. |
| `BenchmarkDotNet.Templates` | `benchmark` | Scaffolds a BenchmarkDotNet project with the correct harness wiring. Used when profiling hot paths in the forge (Svartálfheim) or any realm where allocation and throughput matter. |

## Build your own bridge

Bifröst is a reference composition, not a destination for contributions. The realms are the product; this repository just demonstrates one way to bridge them.

The intended pattern is to **create your own meta-repository from the constituent parts**: take the realms you need as submodules, write your own AppHost, and swap the runtime containers — database, message broker, cache, identity provider — for whatever direction your platform is going. The substrate doesn't care which containers you compose against it; that is the point.

Two consequences of that design, both deliberate:

- **Contributions belong in the realms.** Changes to primitives go to Svartálfheim, contracts to Asgard, implementations to Midgard, hosting to Yggdrasil. Pull requests here should be rare — composition fixes, not features.
- **Submodule URLs are relative** (`../Svartalfheim.git`), resolved against whatever remote you cloned Bifröst from. That's what makes HTTPS and SSH both work from a single `.gitmodules` — and it means a *fork* of Bifröst resolves submodules against the fork's owner, failing loudly unless the realms are forked alongside it. If you find yourself forking Bifröst, that's the signal you've reached the moment to build your own bridge instead.

## Soundtrack: Across the Rainbow Bridge
[![Soundtrack: Across the Rainbow Bridge](https://img.youtube.com/vi/mhqn3QSedwY/maxresdefault.jpg)](https://www.youtube.com/watch?v=mhqn3QSedwY)
