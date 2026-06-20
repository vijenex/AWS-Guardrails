# protect-org-structure

## What this does
Blocks deletion of AWS Organizations structural components (OUs, removing accounts), AWS Directory Service directories, IAM Identity Store objects, and foundational VPC networking components (VPC, subnet, IGW). Preserves the governance inheritance hierarchy and core network infrastructure.

## Why you need this
The AWS Organizations OU hierarchy is your governance delivery mechanism — every SCP, Config rule, and CloudTrail configuration flows through it. Deleting an OU:
- Immediately removes all SCPs from accounts that were in that OU
- Can orphan accounts from centralized billing and security monitoring
- Cannot be easily undone if accounts are mid-deletion

AWS Directory Service deletions remove authentication infrastructure for all accounts using AWS Managed Microsoft AD or Simple AD. IAM Identity Store deletions remove SSO users and groups, potentially locking everyone out.

VPC and IGW deletions are included because the core networking foundation is as critical as the compute — deleting the VPC of a production network account causes an immediate outage across all peered and routed accounts.

## Security impact if you don't apply this
- An attacker with Organizations admin permissions can remove accounts from the org, stripping all SCPs in one action.
- A Directory deletion disables all LDAP/AD authentication across the org.
- An IGW deletion for a shared VPC account causes instant internet connectivity loss for all downstream accounts.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This policy blocks VPC deletion, which includes sandbox and dev VPCs. In environments where VPCs are created and destroyed as part of normal development workflows, apply this policy only to production and shared-services OUs, not developer sandboxes.

**Step 1 — Sandbox**: Apply and verify `organizations:DeleteOrganizationalUnit` returns `AccessDenied`. Verify `ec2:DeleteVpc` returns `AccessDenied`.

**Step 2 — Non-production**: Review automated infrastructure teardown scripts. Ensure dev environment teardown is in a separate OU not covered by this policy.

**Step 3 — Production**: Apply to production and shared-services OUs. Apply to networking accounts immediately.

**Vijenex is not responsible for teardown workflow failures from applying this policy.**

## Prerequisites
- Ensure developer and sandbox OUs are in separate OUs not covered by this policy (they need VPC deletion for ephemeral environments).
- Document the emergency procedure for legitimate org structural changes (management account action).

## How to apply
```bash
aws organizations create-policy \
  --name "protect-org-structure" \
  --description "Block deletion of org structure, directories, and core networking" \
  --content file://protect-org-structure.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to delete an OU — expect AccessDenied
aws organizations delete-organizational-unit --organizational-unit-id ou-REPLACE

# Attempt to delete a VPC — expect AccessDenied
aws ec2 delete-vpc --vpc-id vpc-REPLACE
```

## Exceptions and customisation
- To allow ephemeral VPC deletion in dev/sandbox OUs, do not apply this policy to those OUs.
- The `identitystore:Delete*` wildcard covers deleting users, groups, and memberships in IAM Identity Center. Do not narrow this — all identity store deletions should be protected.

## References
- [AWS Organizations — OU structure best practices](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices.html)
- [AWS IAM Identity Center security](https://docs.aws.amazon.com/singlesignon/latest/userguide/security.html)
- [MITRE ATT&CK — T1531 Account Access Removal](https://attack.mitre.org/techniques/T1531/)
