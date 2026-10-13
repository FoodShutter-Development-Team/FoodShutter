# Security scope

FoodShutter is a course prototype. Presentation security goals do not establish a completed production audit, verified RLS installation or service-level guarantee.

## Credentials and data

Keep Supabase service-role credentials and model API keys on the backend. Web and iOS use public Supabase configuration. Never put a server credential or signing key in a client build or `NEXT_PUBLIC_` variable.

Uploads verify Supabase bearer tokens and derive ownership from the token. Isolation of client-accessible tables and objects depends on deployed RLS and Storage policies, which are absent as versioned SQL in this repository. Client-side filtering does not replace policy enforcement.

The backend uploads photographs to Supabase Storage. Optional debug output can contain images and model responses. Treat photographs, personal profiles and dietary records as personal data with controlled access and defined retention.

## Current source observations

- iOS uses a LAN HTTP endpoint and allows arbitrary transport loads. Public deployment needs HTTPS and restrictive ATS settings.
- iOS obtains signed photo URLs; the web adapter constructs public URLs and needs private-access support for private buckets.
- No database migration or RLS SQL is included, so presentation claims require independent deployed-policy verification.
- iOS deletion currently removes a profile, and the web action displays an alert. Complete Auth, related-record and Storage deletion is not established.
- JWT verification has no separately configured explicit issuer check. Validate project-specific token behavior and negative cases before release.
- Upload size is checked after the file is read. Public deployment also needs ingress limits and content validation.

[Deployment requirements](docs/deployment.md) describe remaining work. This documentation does not change runtime behavior.

## Reporting

Use GitHub private vulnerability reporting if enabled. Otherwise, use a private contact method published by a maintainer. Do not post credentials, personal images or sensitive exploit details in a public issue.

Provide the source commit, affected component, reproduction using synthetic data and observed impact. The repository does not promise a response time or paid support agreement.
