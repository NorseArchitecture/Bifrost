using Aspire.Hosting;
using Norse.Orchestration.AppHost;

Console.Title = "Architecture Aspire App Host";

var builder = DistributedApplication.CreateBuilder(args);
// PostgreSQL w/ Timescale extensions and pgAdmin
const string PostgresName = "norse-postgres";
var postgres = builder
	.AddPostgres(PostgresName, password: builder.AddParameter($"{PostgresName}-password", "look", secret: true), port: 5432)
	.WithContainerDefaults("19beta1-trixie", true)
	.WithDataVolume(PostgresName);

var auth = postgres
	.WithPgAdmin(container => container
		.WithParentRelationship(postgres)
		.WithUrlForEndpoint("http", static url => url.DisplayText = "pgAdmin"))
	.AddDatabase("Auth");

var migrationsService = builder
	.AddProject<Projects.Hosting_Migrations_Service>("MigrationsService")
	.WithReference(auth)
	.WaitFor(auth);

await builder.Build().RunAsync().ConfigureAwait(false);
