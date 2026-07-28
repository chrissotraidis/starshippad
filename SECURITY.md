# Security policy

Report security-sensitive StarshipPad problems privately to the repository
owner through GitHub's private vulnerability-reporting feature when it is
available. Do not publish credentials, signing identities, provisioning
profiles, private ROM hashes tied to a user, or exploitable details in a
public issue.

Ordinary build failures, gameplay defects, unsupported ROM messages, and
touch-layout problems are not security reports and should use a normal issue.

StarshipPad does not distribute game data. A report must never include a ROM,
ROM-derived archive, extracted Nintendo asset, or download link. The
repository safety gate treats the appearance of that material as a
stop-everything defect.

Only the current `main` branch is supported. Upstream Starship, LibUltraShip,
and Torch are separately maintained projects; report upstream vulnerabilities
through their own published security processes only after confirming the
problem is not introduced by StarshipPad's maintained patches.
