# restrict-multiaz

## What this does
Blocks creating Multi-AZ ElastiCache clusters and Multi-AZ RDS DB instances. Intended for non-production OUs (sandbox, development, QA) where high availability is not required and the 2x cost of Multi-AZ is wasteful.

## Why you need this
Multi-AZ deployments roughly double the cost of RDS and ElastiCache. In a large organization with dozens of developer and sandbox accounts:
- Engineers routinely create Multi-AZ resources out of habit or by copying production configs.
- Each inadvertently Multi-AZ dev database costs $50–$500/month extra.
- At scale, this creates thousands of dollars of monthly unnecessary spend across hundreds of developer accounts.

This is a **cost governance** control, not a security control. Apply it to non-production OUs to enforce cost hygiene.

## Security impact if you don't apply this
No direct security impact. This is a FinOps/cost control.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: Do NOT apply to production or pre-production OUs. Multi-AZ is a reliability and availability requirement in production. This policy is strictly for sandbox and development OUs.

**Step 1 — Sandbox OU only**: Apply and verify Multi-AZ RDS creation fails. Verify single-AZ creation succeeds.

**Step 2 — Development OUs**: Apply and communicate the change to developers. Some may have legitimate test cases requiring HA — provide a documented exception process.

**Do NOT apply Step 3 (production)**. This policy should never be applied to production.

**Vijenex is not responsible for availability incidents if this policy is mistakenly applied to a production OU.**

## Prerequisites
Ensure you are targeting only sandbox/development OUs in your `attach-policy` command. Double-check the OU ID before applying.

## How to apply
```bash
aws organizations create-policy \
  --name "restrict-multiaz-nonprod" \
  --description "Block Multi-AZ RDS and ElastiCache in non-production OUs" \
  --content file://restrict-multiaz.json \
  --type SERVICE_CONTROL_POLICY

# IMPORTANT: Only attach to sandbox/dev OUs — NOT production
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <SANDBOX_OR_DEV_OU_ID>
```

## How to test
```bash
# Attempt Multi-AZ RDS — expect AccessDenied
aws rds create-db-instance \
  --db-instance-identifier test-ha \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password TestPass123 \
  --storage-encrypted \
  --allocated-storage 20 \
  --multi-az

# Single-AZ — expect success
aws rds create-db-instance \
  --db-instance-identifier test-single \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password TestPass123 \
  --storage-encrypted \
  --allocated-storage 20 \
  --no-multi-az
```

## Exceptions and customisation
- To allow Multi-AZ for specific teams who need HA testing, create a sub-OU for them and exclude it from this policy.
- This policy does not block Aurora — Aurora always has multi-AZ storage replication built in (but its instances can still be single-AZ in the writer/reader sense). Block `rds:CreateDBCluster` with `MultiAZ=true` separately if needed.

## References
- [AWS RDS Multi-AZ overview](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [AWS FinOps — cost optimization for dev environments](https://aws.amazon.com/aws-cost-management/cost-optimization/)
