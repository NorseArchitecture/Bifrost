Console.Title = "Architecture Aspire App Host";

var builder = DistributedApplication.CreateBuilder(args);
// PostgreSQL w/ Timescale extensions and pgAdmin
const string postgresName = "norse-postgres";
var postgres = builder
	.AddPostgres(postgresName, password: builder.AddParameter($"{postgresName}-password", settings.Relational, secret: true), port: 5432)
	.WithContainerDefaults(proxyEnabled: true)
    .WithImageTag("19beta1-trixie")
	.WithDataVolume(postgresName);

var auth = postgres
	.WithPgAdmin(container => container
		.WithContainerDefaults(proxyEnabled: true)
		.WithParentRelationship(relational)
		.WithUrlForEndpoint("http", static url => url.DisplayText = "pgAdmin"))
	.AddDatabase("Auth");

var migrationsService = builder
	.AddProject<Projects.Hosting_MigrationsService>("MigrationsService")
	.WithReference(auth)
	.WaitFor(auth);

await builder.Build().RunAsync().ConfigureAwait(false);
