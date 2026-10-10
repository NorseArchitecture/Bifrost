using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using Aspire.Hosting.Publishing;

namespace Norse.Orchestration.AppHost;

/// <summary>
///     Generates the local-dev OpenIddict signing and encryption certificate: one self-signed RSA certificate
///     exported as an empty-password PFX, base64-encoded. The empty password is deliberate. The parameter
///     carrying this value is already <c>secret: true, persist: true</c>, so a second secret guarding the PFX
///     container adds no defense in depth for a local-dev credential, and two independently generated
///     parameters (a PFX and its password) could never reach each other.
/// </summary>
sealed class OidcSigningCertificateParameterDefault : ParameterDefault
{
	/// <inheritdoc />
	public override string GetDefaultValue()
	{
		using var rsa = RSA.Create(2048);
		CertificateRequest request = new("CN=Norse OpenIddict (local dev)", rsa, HashAlgorithmName.SHA256,
			RSASignaturePadding.Pkcs1);
		using var certificate = request.CreateSelfSigned(
			DateTimeOffset.UtcNow.AddMinutes(-5), DateTimeOffset.UtcNow.AddYears(2));

		return Convert.ToBase64String(certificate.Export(X509ContentType.Pfx, password: string.Empty));
	}

	/// <inheritdoc />
	public override void WriteToManifest(ManifestPublishingContext context) =>
		// A local-dev generated secret, the same posture as postgres-password: never a publish concern until
		// this AppHost targets a cloud publish profile, which it does not.
		throw new NotSupportedException(
			"The OpenIddict signing certificate is a local-dev generated secret and is not manifest-publishable.");
}
