# deny-org-leave

## What this does
Three combined controls: (1) prevents member accounts from leaving the AWS Organization, (2) prevents account closure via the Account API, (3) blocks creating or updating AWS RAM resource shares that allow external principals (outside the organization).

## Why you need this
**Account escape**: An attacker who compromises an account admin could remove the account from your Organization, instantly dropping all SCPs, Config rules, GuardDuty master membership, and Security Hub aggregation. The escaped account then operates with no governance controls.

**Account closure**: Closing an account deletes all resources and cannot be undone for a 90-day suspension period. Accidental or malicious account closure is an extreme data destruction event.

**External RAM sharing**: AWS Resource Access Manager (RAM) allows sharing VPCs, Transit Gateways, and other resources. Sharing with external principals (outside your org) can create unexpected cross-organization network paths or data access.

## Security impact if you don't apply this
- A compromised account owner can remove the account from your org in 30 seconds, escaping all governance.
- An account that leaves the org retains its resources but loses all centralized security monitoring.
- RAM external sharing can expose your internal network resources to unknown third-party accounts.

## ⚠️ Disclaimer and Testing Ladder
This policy has minimal operational impact — these actions should never happen in normal operations.

**Step 1 — Sandbox**: Attempt `organizations:LeaveOrganization` — expect `AccessDenied`. Attempt to create an external RAM share — expect `AccessDenied`.

**Step 2 — Non-production**: Apply and verify no automated processes attempt to leave the org (this should be zero).

**Step 3 — Production**: Apply immediately. This is a low-risk policy — the actions it blocks are almost never legitimate in production.

**Vijenex is not responsible for any issues from applying this policy.**

## How to apply
```bash
aws organizations create-policy \
  --name "deny-org-leave" \
  --description "Block leaving org, account closure, and external RAM sharing" \
  --content file://deny-org-leave.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to leave organization — expect AccessDenied
aws organizations leave-organization

# Attempt to create external RAM share — expect AccessDenied
aws ram create-resource-share \
  --name test-external \
  --allow-external-principals \
  --principals "999999999999"
```

## Exceptions and customisation
- **Account decommissioning**: when you legitimately need to close or migrate an account, remove it from this OU first (management account action), perform the closure, then this SCP is no longer applicable.
- Internal RAM sharing (within your org) is not blocked.

## References
- [AWS Organizations — Removing accounts](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html)
- [AWS RAM — Resource sharing best practices](https://docs.aws.amazon.com/ram/latest/userguide/security-best-practices.html)
- [MITRE ATT&CK — T1531 Account Access Removal](https://attack.mitre.org/techniques/T1531/)
