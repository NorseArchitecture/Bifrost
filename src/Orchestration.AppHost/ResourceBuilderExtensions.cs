using Aspire.Hosting;
using Aspire.Hosting.ApplicationModel;

namespace Norse.Orchestration.AppHost;

static class ResourceBuilderExtensions
{
	extension<T>(IResourceBuilder<T> builder) where T : ContainerResource
	{
		// Some services require proxy to work (Redis, Seq, & ServiceControl) but most do not only enable it when necessary
		// Go ahead and pull the latest image in development and set the tag to default to latest
		// I have found debugging starts and stops go better with persistent containers
		internal IResourceBuilder<T> WithContainerDefaults(string? tag = null, bool proxyEnabled = false) => builder
			.WithEndpointProxySupport(proxyEnabled)
			.WithImagePullPolicy(ImagePullPolicy.Always)
			.WithImageTag(tag ?? "latest")
			.WithLifetime(ContainerLifetime.Persistent);
	}
}
