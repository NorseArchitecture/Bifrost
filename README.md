# Bifrost

> The rainbow bridge between the realms, watched over by Heimdall.

![Bifrost — the shimmering rainbow bridge spanning the nine realms, the only passage between worlds](https://github.com/user-attachments/assets/ef2ba252-9011-4aec-a08e-a8434e16a43f "Bifrost — the rainbow bridge between the realms")

*Image credit: [@norsemythologyclips](https://www.instagram.com/norsemythologyclips/) — go follow them.*

The local developer meta-repository for the Norse platform — `Norse.Orchestration.*`, the .NET Aspire AppHost that composes every resource required to run and develop the platform: services, databases, queues, and configuration. Clone once, cross the bridge, and every realm grown on Yggdrasil is running.

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
| [Himinbjorg](https://github.com/NorseArchitecture/Himinbjorg) | `Norse.Identity.*` — EF persistence for ASP.NET Identity and OpenIddict: entities, conventions, and migrations; sealed server-side, never referenced from WASM or MAUI |
| [Heimdall](https://github.com/NorseArchitecture/Heimdall) | `Norse.Access.*` — auth services on Himinbjorg: one access ruleset across Blazor Server, WASM, and MAUI, with admin Blazor components and the backing gRPC service |
| [Naglfar](https://github.com/NorseArchitecture/Naglfar) | `Norse.DesignSystem.*` — design tokens, radii, and component primitives, assembled from the unglamorous remnants into something seaworthy enough to carry every product UI |
| [Glitnir](https://github.com/NorseArchitecture/Glitnir) | *(docs only)* — the design court: specs, plans, and proof-of-concept verdicts; every design is tried there before code is forged |

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

## Build your own bridge

Bifrost is a reference composition, not a destination for contributions. The realms are the product; this repository just demonstrates one way to bridge them.

The intended pattern is to **create your own meta-repository from the constituent parts**: take the realms you need as submodules, write your own AppHost, and swap the runtime containers — database, message broker, cache, identity provider — for whatever direction your platform is going. The substrate doesn't care which containers you compose against it; that is the point.

Two consequences of that design, both deliberate:

- **Contributions belong in the realms.** Changes to primitives go to Svartalfheim, contracts to Asgard, implementations to Midgard, hosting to Yggdrasil. Pull requests here should be rare — composition fixes, not features.
- **Submodule URLs are relative** (`../Svartalfheim.git`), resolved against whatever remote you cloned Bifrost from. That's what makes HTTPS and SSH both work from a single `.gitmodules` — and it means a *fork* of Bifrost resolves submodules against the fork's owner, failing loudly unless the realms are forked alongside it. If you find yourself forking Bifrost, that's the signal you've reached the moment to build your own bridge instead.
