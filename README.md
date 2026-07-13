# Bifröst

> The rainbow bridge between the realms, watched over by Heimdall.

![Bifröst — the shimmering rainbow bridge spanning the nine realms, the only passage between worlds](https://github.com/user-attachments/assets/ef2ba252-9011-4aec-a08e-a8434e16a43f "Bifröst — the rainbow bridge between the realms")

*Image credit: [@norsemythologyclips](https://www.instagram.com/norsemythologyclips/) — go follow them.*

The local developer meta-repository for the Norse platform — `Norse.Orchestration.*`, the .NET Aspire AppHost that composes every resource required to run and develop the platform: services, databases, queues, and configuration. Clone once, cross the bridge, and every realm grown on Yggdrasil is running.

## What's live: the migrations framework

Six realms, one dependency order, zero shortcuts. The first piece of runtime composition Bifröst exists to prove — a real service, wired into the Aspire dashboard, doing real work against a real database — landed end to end:

- **Asgard** declared `IMigrationContributor` — no `Order`, no `DependsOn`, because contributors are physically incapable of seeing each other's data.
- **Midgard** built `MigrationRunnerService`, the hosted service that runs every contributor and exits clean — or throws loud and hard, no swallowed exceptions.
- **Urdarbrunnr** shipped the EF foundation and this platform's first Roslyn source generator: it discovers every contributor at compile time and emits `AddNorseMigrations()`, proven identical whether contributors arrive as `ProjectReference` (this repo, today) or `PackageReference` (NuGet, tomorrow).
- **Himinbjörg** proved it against the hardest brownfield case there is: the full ASP.NET Core Identity v3 + OpenIddict schema, entities and all, landing in a real `norse_identity` Postgres database.
- **Yggdrasil**'s migrations service went from a `Placeholder.cs` stub to a three-line `Program.cs` that never has to change again, no matter how many bounded contexts join the platform.
- **Bifröst** wired a Postgres primary + streaming replica into the Aspire dashboard and pointed the migrations service at it.

Run it: `dotnet run --project src/Orchestration.AppHost`, watch `migrations` clear the dashboard green, then check `norse_identity` — the schema is real, not a sketch. Full design and task-by-task ship log: [Glitnir's migrations framework plan](https://github.com/NorseArchitecture/Glitnir/blob/master/docs/Platform/plans/2026-06-28-migrations-framework-identity-schema.md).

**Where this is headed:** identity was the proving vehicle, not the destination. The same six-step relay — contract in Asgard, runner in Midgard, EF chassis in Urdarbrunnr, schema in the owning realm, wiring in Yggdrasil, composition in Bifröst — is now the template every future bounded context follows to get its own `norse_{context}` database online. Broker and cache containers are next in the open decisions queue.

## The realms on the bridge

Each realm is a git submodule, pinned to track `master`. Repositories carry the lore; namespaces carry the function:

| Submodule | The function |
|---|---|
| [Svartalfheim](https://github.com/NorseArchitecture/Svartalfheim) | `Norse.Primitives.*` — the forge: `Result<T>`, the parsing stack, and the analyzers and BuildCheck rules that strike when law is broken |
| [Asgard](https://github.com/NorseArchitecture/Asgard) | `Norse.Abstractions.*` — declared law: contracts, attribute model, plugin interfaces, mediator law |
| [Midgard](https://github.com/NorseArchitecture/Midgard) | `Norse.Infrastructure.*` — embodied law: concrete persistence, mediator runtime, API, UI Composition framework |
| [Urdarbrunnr](https://github.com/NorseArchitecture/Urdarbrunnr) | `Norse.EntityFramework.*` — entity base types, DbContext foundations, conventions, value converters, and the migrations chassis |
| [Ratatoskr](https://github.com/NorseArchitecture/Ratatoskr) | `Norse.NServiceBus.*` — NServiceBus endpoint configuration, saga infrastructure, message conventions, and transport wiring; the squirrel that carries messages between the realms |
| [Yggdrasil](https://github.com/NorseArchitecture/Yggdrasil) | `Norse.Hosting.*` — hosting runtimes and deployables: web server, worker, migration service, WASM client, and MAUI app |
| [Himinbjörg](https://github.com/NorseArchitecture/Himinbjorg) | `Norse.Identity.*` — EF persistence for ASP.NET Identity and OpenIddict: entities, conventions, and migrations; sealed server-side, never referenced from WASM or MAUI |
| [Heimdall](https://github.com/NorseArchitecture/Heimdall) | `Norse.AuthN.*` — the authn story on Himinbjörg's identity record: login, register, forgot-password, 2FA setup, recovery, and reset, uniform across Blazor Server, WASM, and MAUI, with the backing gRPC service |
| [Mímisbrunnr](https://github.com/NorseArchitecture/Mimisbrunnr) | `Norse.ReferenceData.Data` — entities, view models, TSV seeders (nietras Sep), and migrations for canonical reference data: ISO country/currency codes, IANA time zones |
| [Mímir](https://github.com/NorseArchitecture/Mimir) | `Norse.ReferenceData.Components` / `.Web.Server` / `.Worker` — the serving layer on Mímisbrunnr: Blazor components, gRPC service host, and the background worker that keeps reference data current |
| [Naglfar](https://github.com/NorseArchitecture/Naglfar) | `Norse.DesignSystem.*` — the token pipeline (`@norsearchitecture/design-tokens`, Style Dictionary), assembled from the unglamorous remnants into something seaworthy enough to carry every product UI. npm-first — one 100%-generated .NET package (`DesignSystem.Tokens`), no hand-authored C# |
| [Bragi](https://github.com/NorseArchitecture/Bragi) | `Norse.DesignSystem.Stories` — the content-only Razor Class Library of `.stories.razor` catalog pages that Yggdrasil's BlazingStory host serves; split out of Naglfar 2026-07-12 |
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
| `ParticularTemplates` | `nsbendpoint`, `nsbhandler`, `nsbsaga` | Official NServiceBus scaffolding from Particular Software — endpoint, message handler, and saga stubs wired to NServiceBus conventions. Ratatoskr (`Norse.NServiceBus.*`) is the realm that consumes these. |
| `Aspire.ProjectTemplates` | `aspire-apphost`, `aspire-servicedefaults`, and others | Official Aspire scaffolding. `aspire-apphost` is the template for new bridge AppHost projects; `aspire-servicedefaults` scaffolds the service-defaults project the platform intentionally places in Midgard (`Norse.Infrastructure.*`) rather than the AppHost. The starter and test templates (`aspire-starter`, `aspire-xunit`, etc.) are bundled but unused here. |
| `BenchmarkDotNet.Templates` | `benchmark` | Scaffolds a BenchmarkDotNet project with the correct harness wiring. Used when profiling hot paths in the forge (Svartalfheim) or any realm where allocation and throughput matter. |

## Build your own bridge

Bifröst is a reference composition, not a destination for contributions. The realms are the product; this repository just demonstrates one way to bridge them.

The intended pattern is to **create your own meta-repository from the constituent parts**: take the realms you need as submodules, write your own AppHost, and swap the runtime containers — database, message broker, cache, identity provider — for whatever direction your platform is going. The substrate doesn't care which containers you compose against it; that is the point.

Two consequences of that design, both deliberate:

- **Contributions belong in the realms.** Changes to primitives go to Svartalfheim, contracts to Asgard, implementations to Midgard, hosting to Yggdrasil. Pull requests here should be rare — composition fixes, not features.
- **Submodule URLs are relative** (`../Svartalfheim.git`), resolved against whatever remote you cloned Bifröst from. That's what makes HTTPS and SSH both work from a single `.gitmodules` — and it means a *fork* of Bifröst resolves submodules against the fork's owner, failing loudly unless the realms are forked alongside it. If you find yourself forking Bifröst, that's the signal you've reached the moment to build your own bridge instead.

## Soundtrack: Across the Rainbow Bridge
[![Soundtrack: Across the Rainbow Bridge](https://img.youtube.com/vi/mhqn3QSedwY/maxresdefault.jpg)](https://www.youtube.com/watch?v=mhqn3QSedwY)
