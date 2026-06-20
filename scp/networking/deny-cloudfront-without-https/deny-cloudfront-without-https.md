# deny-cloudfront-without-https

## What this does
Blocks creating or updating a CloudFront distribution with `ViewerProtocolPolicy` set to `allow-all`, which would permit HTTP connections. Only distributions configured with `https-only` or `redirect-to-https` can be created or updated.

## Why you need this
CloudFront distributions with `allow-all` viewer protocol serve content over plain HTTP as well as HTTPS. HTTP connections:
- Are unencrypted in transit — any network observer (ISP, coffee shop WiFi, corporate proxy) can read and modify the content.
- Expose cookies, session tokens, and authentication headers to interception.
- Are vulnerable to content injection attacks where an attacker on the network path injects malicious JavaScript or HTML.
- Fail modern browser mixed-content checks, leaking secure sites' credibility.

Google, Apple, and modern browsers have increasingly penalized or blocked non-HTTPS content. TLS certificates are free via ACM. There is no legitimate reason for a CloudFront distribution to allow HTTP in 2024+.

## Security impact if you don't apply this
- Auth cookies for HTTP-served pages can be stolen by network attackers.
- Session hijacking is trivial over HTTP — tokens transmitted in requests are plaintext.
- PCI-DSS requirement 6.5 (secure communications), HIPAA §164.312(e)(1), and NIST SP 800-52 all require encrypted transport for sensitive data.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: Applying this policy will prevent updating any existing distribution whose viewer protocol policy is `allow-all`. Existing distributions continue serving HTTP — but they cannot be updated until the protocol policy is changed to `redirect-to-https` or `https-only`.

**Step 1 — Sandbox**: Create a distribution with `allow-all` — expect `AccessDenied`.

**Step 2 — Non-production**: Inventory distributions with HTTP allowed:
```bash
aws cloudfront list-distributions \
  --query "DistributionList.Items[*].{ID:Id,Domains:Aliases.Items,HTTP:DefaultCacheBehavior.ViewerProtocolPolicy}" \
  | jq '.[] | select(.HTTP == "allow-all")'
```
Update them to `redirect-to-https`, then apply.

**Step 3 — Production**: Apply during low-traffic window. Monitor CloudFront access logs for increased HTTPS redirect responses.

**Vijenex is not responsible for distribution update failures from applying this policy without the testing ladder.**

## Prerequisites
Migrate all distributions to `redirect-to-https` or `https-only` before applying. Use ACM to provision free TLS certificates.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-cloudfront-without-https" \
  --description "Block CloudFront distributions without HTTPS enforcement" \
  --content file://deny-cloudfront-without-https.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to create distribution with allow-all — expect AccessDenied
# Use a CloudFormation template or the console with ViewerProtocolPolicy: allow-all
# Or via CLI with a distribution config JSON that includes "allow-all"
```

## Exceptions and customisation
If you need HTTP for a specific legacy distribution (e.g., serving cached content to HTTP-only IoT devices), handle that at the distribution level, not by weakening this SCP.

## References
- [CloudFront viewer protocol policy options](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/secure-connections-supported-viewer-protocols-ciphers.html)
- [AWS Certificate Manager — free TLS certs](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html)
- [PCI-DSS v4.0 — 6.5.2 Secure communications](https://www.pcisecuritystandards.org/)
