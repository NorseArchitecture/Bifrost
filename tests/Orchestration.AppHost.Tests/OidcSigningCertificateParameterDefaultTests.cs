using System.Security.Cryptography.X509Certificates;

namespace Norse.Orchestration.AppHost.Tests;

public sealed class OidcSigningCertificateParameterDefaultTests
{
	[Fact]
	void GetDefaultValue_returns_a_loadable_empty_password_PFX()
	{
		OidcSigningCertificateParameterDefault subject = new();

		var base64 = subject.GetDefaultValue();

		using var certificate = X509CertificateLoader.LoadPkcs12(Convert.FromBase64String(base64), password: null);
		certificate.HasPrivateKey.ShouldBeTrue();
	}

	[Fact]
	void GetDefaultValue_returns_a_certificate_valid_right_now()
	{
		OidcSigningCertificateParameterDefault subject = new();

		using var certificate = X509CertificateLoader.LoadPkcs12(
			Convert.FromBase64String(subject.GetDefaultValue()), password: null);

		certificate.NotBefore.ShouldBeLessThanOrEqualTo(DateTime.Now);
		certificate.NotAfter.ShouldBeGreaterThan(DateTime.Now);
	}

	[Fact]
	void Two_calls_generate_two_independent_certificates()
	{
		// Aspire persists the first generated value, so in practice GetDefaultValue runs once per
		// AppHost; it must still never memoize, so two instances never collide on thumbprint.
		OidcSigningCertificateParameterDefault first = new();
		OidcSigningCertificateParameterDefault second = new();

		using var firstCertificate = X509CertificateLoader.LoadPkcs12(
			Convert.FromBase64String(first.GetDefaultValue()), password: null);
		using var secondCertificate = X509CertificateLoader.LoadPkcs12(
			Convert.FromBase64String(second.GetDefaultValue()), password: null);

		firstCertificate.Thumbprint.ShouldNotBe(secondCertificate.Thumbprint);
	}
}
