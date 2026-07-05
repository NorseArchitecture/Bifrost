using Aspire.Hosting;
using Norse.Orchestration.AppHost;

Console.Title = "Norse Architecture — Aspire App Host";

var builder = DistributedApplication.CreateBuilder(args);

// PostgreSQL primary + streaming replica. Fixed, unproxied host ports (WithContainerDefaults'
// default proxyEnabled: false) so DataGrip/psql reach 5432/5433 directly, independent of AppHost
// run state. See postgres/replication-hba.sh and postgres/replica-entrypoint.sh for the bootstrap.
var pgPassword = builder.AddParameter("postgres-password", secret: true);

var pgPrimary = builder
	.AddPostgres("pg-primary", password: pgPassword, port: 5432)
	.WithContainerDefaults("19beta1-trixie")
	// WithDataVolume() mis-detects the data directory for beta-tagged images: it parses the major
	// version by int-parsing the tag segment before the first hyphen, and "19beta1" (no separator
	// between the version and "beta1") fails to parse, so it silently falls back to the pre-18
	// path (/var/lib/postgresql/data) even though this image's real PGDATA nests under
	// /var/lib/postgresql/19/docker. Mount the parent directory directly instead.
	.WithVolume("norse-pg-primary", "/var/lib/postgresql")
	.WithArgs(
		"-c", "wal_level=replica",
		"-c", "max_wal_senders=10",
		"-c", "max_replication_slots=10",
		"-c", "hot_standby=on")
	.WithBindMount("postgres/replication-hba.sh", "/docker-entrypoint-initdb.d/01-replication-hba.sh", isReadOnly: true);

pgPrimary.WithPgAdmin(container => container
	.WithParentRelationship(pgPrimary)
	.WithUrlForEndpoint("http", static url => url.DisplayText = "pgAdmin"));

// Aspire resource names allow only ASCII letters, digits, and hyphens (ASPIRE006) — "norse_identity"
// is rejected there, so the resource is "norse-identity" while the actual Postgres database keeps
// the snake_case name. Himinbjörg's published NorseIdentityMigrationContributor is decorated
// [MigrationConnectionString("norse_identity")] — that literal connection-string name is fixed by
// already-shipped code, so the WithReference below re-maps it via the connectionName override.
var norseIdentity = pgPrimary.AddDatabase("norse-identity", databaseName: "norse_identity");

// Mímisbrunnr's published NorseReferenceDataMigrationContributor is decorated
// [MigrationConnectionString("norse_referencedata")] — same ASPIRE006 dash-vs-underscore split as
// norse-identity above, re-mapped via the connectionName override on WithReference below.
var norseReferenceData = pgPrimary.AddDatabase("norse-referencedata", databaseName: "norse_referencedata");

builder
	.AddContainer("pg-replica", "postgres")
	.WithContainerDefaults("19beta1-trixie")
	// Mount the named volume at the image's own declared VOLUME path (/var/lib/postgresql), not a
	// subdirectory of it — otherwise Docker still auto-creates an anonymous volume for the
	// declared path itself (uncovered by a child-path mount), same class of bug as the primary's
	// WithDataVolume() mis-detection above. PGDATA below is a subdirectory of the named mount.
	.WithVolume("norse-pg-replica", "/var/lib/postgresql")
	.WithEnvironment("PGDATA", "/var/lib/postgresql/data")
	.WithEnvironment("POSTGRES_PASSWORD", pgPassword)
	.WithBindMount("postgres/replica-entrypoint.sh", "/entrypoint.sh", isReadOnly: true)
	.WithEntrypoint("/bin/bash")
	.WithArgs("/entrypoint.sh")
	.WithEndpoint(port: 5433, targetPort: 5432, name: "tcp", isProxied: false)
	.WaitFor(pgPrimary);

var migrationsService = builder
	.AddProject<Projects.Hosting_Migrations_Service>("migrations")
	.WithReference(norseIdentity, connectionName: "norse_identity")
	.WithReference(norseReferenceData, connectionName: "norse_referencedata")
	.WaitFor(norseIdentity)
	.WaitFor(norseReferenceData);

await builder.Build().RunAsync().ConfigureAwait(false);
