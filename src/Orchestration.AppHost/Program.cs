var builder = DistributedApplication.CreateBuilder(args);

// Local container credentials — read from appsettings.json Parameters section.
// These are Docker container passwords, not cloud secrets; appsettings.json is
// the right home and is committed to the repo.
var postgresPassword = builder.AddParameter("postgres-password");
var rabbitmqUser = builder.AddParameter("rabbitmq-user");
var rabbitmqPassword = builder.AddParameter("rabbitmq-password");

// TimescaleDB HA — the single relational + time-series store.
// PGDATA quirk: timescaledb-ha places data at /home/postgres/pgdata, not the
// standard Postgres path. The volume target must match or data does not persist.
var timescale = builder.AddContainer("timescale", "timescale/timescaledb-ha", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithEnvironment("POSTGRES_USER", "postgres")
	.WithEnvironment("POSTGRES_PASSWORD", postgresPassword)
	.WithEnvironment("POSTGRES_DB", "norse")
	.WithVolume("norse-relational", "/home/postgres/pgdata")
	.WithEndpoint(port: 5432, targetPort: 5432, name: "pg", isProxied: false);

// RabbitMQ — management variant for HTTP API; floating tag, developer machine
// is the canary for version breakage.
var rabbit = builder.AddContainer("rabbit", "rabbitmq", "management")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithEnvironment("RABBITMQ_DEFAULT_USER", rabbitmqUser)
	.WithEnvironment("RABBITMQ_DEFAULT_PASS", rabbitmqPassword)
	.WithVolume("norse-messaging", "/var/lib/rabbitmq")
	.WithEndpoint(port: 5672, targetPort: 5672, name: "amqp", isProxied: false)
	.WithEndpoint(port: 15672, targetPort: 15672, name: "management", isProxied: false);

// MongoDB Atlas Local — includes mongot (Atlas Search / Vector Search) on 27032.
// Chosen over library/mongo because Vector Search is in scope for the AI layer.
var mongo = builder.AddContainer("mongo", "mongodb/mongodb-atlas-local", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithVolume("norse-document", "/data/db")
	.WithEndpoint(port: 27017, targetPort: 27017, name: "mongodb", isProxied: false)
	.WithEndpoint(port: 27032, targetPort: 27032, name: "mongot", isProxied: false);

// ── Particular Software platform ────────────────────────────────────────────
// RavenDB — shared persistence for all three ServiceControl instances.
// A single node serves monitoring, audit, and error stores; developer machines
// do not need the clustering overhead of the production topology.
var ravendb = builder.AddContainer("ravendb", "particular/ravendb", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithVolume("norse-monitoring", "/var/lib/ravendb/data")
	.WithEndpoint(port: 8080, targetPort: 8080, name: "http", isProxied: false);

// ServiceControl (error) — ingests failed messages from the error queue and
// exposes the ServicePulse / ServiceInsight API on port 33333.
// --setup-and-run is idempotent: runs schema migration then starts the host.
// PARTICULARSOFTWARE_LICENSE is intentionally empty; the container will start
// (possibly logging a license warning) but the AppHost will not crash on a
// missing parameter. Wire the real license via user secrets in Task 4.
var servicecontrol = builder.AddContainer("servicecontrol", "particular/servicecontrol", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithEnvironment("TRANSPORTTYPE", "RabbitMQ.QuorumConventionalRouting")
	.WithEnvironment("CONNECTIONSTRING", "host=rabbit")
	.WithEnvironment("RAVENDB_CONNECTIONSTRING", "http://ravendb:8080")
	.WithEnvironment("REMOTEINSTANCES", "[{\"api_uri\":\"http://servicecontrol-audit:44444/api\"}]")
	.WithEnvironment("ENABLEINTEGRATEDSERVICEPULSE", "false")
	.WithEnvironment("PARTICULARSOFTWARE_LICENSE", string.Empty)
	.WithArgs("--setup-and-run")
	.WithEndpoint(port: 33333, targetPort: 33333, name: "http", isProxied: false)
	.WaitFor(ravendb)
	.WaitFor(rabbit);

// ServiceControl Audit — stores all processed messages for audit/replay.
// Stateless beyond RavenDB; --setup-and-run handles schema on first boot.
var servicecontrolAudit = builder.AddContainer("servicecontrol-audit", "particular/servicecontrol-audit", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithEnvironment("TRANSPORTTYPE", "RabbitMQ.QuorumConventionalRouting")
	.WithEnvironment("CONNECTIONSTRING", "host=rabbit")
	.WithEnvironment("RAVENDB_CONNECTIONSTRING", "http://ravendb:8080")
	.WithEnvironment("PARTICULARSOFTWARE_LICENSE", string.Empty)
	.WithArgs("--setup-and-run")
	.WithEndpoint(port: 44444, targetPort: 44444, name: "http", isProxied: false)
	.WaitFor(ravendb)
	.WaitFor(rabbit);

// ServiceControl Monitoring — collects endpoint metrics (throughput, retries).
// No RavenDB dependency; metrics are in-memory by design.
var servicecontrolMonitoring = builder.AddContainer("servicecontrol-monitoring", "particular/servicecontrol-monitoring", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithEnvironment("TRANSPORTTYPE", "RabbitMQ.QuorumConventionalRouting")
	.WithEnvironment("CONNECTIONSTRING", "host=rabbit")
	.WithEnvironment("PARTICULARSOFTWARE_LICENSE", string.Empty)
	.WithArgs("--setup-and-run")
	.WithEndpoint(port: 33633, targetPort: 33633, name: "http", isProxied: false)
	.WaitFor(rabbit);

// ServicePulse — browser dashboard; proxies to ServiceControl and Monitoring.
// Stateless: no volume, no persistent state of its own.
var servicepulse = builder.AddContainer("servicepulse", "particular/servicepulse", "latest")
	.WithLifetime(ContainerLifetime.Persistent)
	.WithImagePullPolicy(ImagePullPolicy.Always)
	.WithEnvironment("SERVICECONTROL_URL", "http://servicecontrol:33333")
	.WithEnvironment("MONITORING_URL", "http://servicecontrol-monitoring:33633")
	.WithEndpoint(port: 9090, targetPort: 9090, name: "http", isProxied: false)
	.WaitFor(servicecontrol)
	.WaitFor(servicecontrolMonitoring);

builder.Build().Run();
