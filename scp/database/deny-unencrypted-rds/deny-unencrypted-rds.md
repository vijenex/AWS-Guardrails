# deny-unencrypted-rds

## What this does
Blocks creation of RDS DB instances, Aurora DB clusters, and EFS file systems without storage encryption enabled. Applies to all relational engine types supported by RDS (MySQL, PostgreSQL, Oracle, SQL Server, MariaDB).

## Why you need this
RDS encryption at rest uses AES-256 and encrypts the underlying storage, automated backups, read replicas, and snapshots. Without it:
- A shared RDS snapshot can be copied to another account in plaintext, exposing your entire database.
- AWS manual snapshots created for DR purposes sit in plaintext in S3-backed storage.
- RDS snapshots can be inadvertently made public — AWS has sent notifications to organizations whose unencrypted RDS snapshots were public.

EFS file systems are frequently used for shared application storage. Unencrypted EFS mounts can be read by any process on any instance that has network access to the mount target.

**Note**: RDS encryption cannot be enabled on an existing instance — you must encrypt at creation time. This makes the SCP prevention critical, as there is no easy remediation path post-creation.

## Security impact if you don't apply this
- **Database plaintext at rest**: all data in the DB, including backups, replicas, and snapshots, is stored in plaintext.
- **Snapshot exposure**: any RDS or EFS snapshot is plaintext and can be shared or made public without key material.
- **Compliance failure**: PCI-DSS 3.5, HIPAA §164.312(a)(2)(iv), SOC 2 CC6.1, and CIS 2.3.1/2.3.2 all require encryption at rest for databases.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This policy blocks new database creation without encryption. Existing unencrypted databases are **not** affected, but you will not be able to create read replicas or restore from snapshots of unencrypted instances once this policy is in effect.

**Step 1 — Sandbox**: Apply and verify creation of an unencrypted RDS instance fails with `AccessDenied`. Verify that creating with encryption succeeds.

**Step 2 — Non-production**: Inventory existing unencrypted RDS instances (`aws rds describe-db-instances --query 'DBInstances[?StorageEncrypted==\`false\`]'`). Note them before applying — they will continue running but you cannot create replicas or restore from their snapshots.

**Step 3 — Production**: Apply during a low-traffic window. Monitor RDS creation CloudTrail events for 48h after applying to confirm no legitimate operations are blocked.

**Vijenex is not responsible for any operational impact from applying this policy without completing the testing ladder.**

## Prerequisites
No prerequisites for new DB creation. For existing unencrypted instances, create an encrypted snapshot and restore to a new encrypted instance before applying.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-unencrypted-rds" \
  --description "Block unencrypted RDS, Aurora, and EFS creation" \
  --content file://deny-unencrypted-rds.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to create unencrypted MySQL instance — expect AccessDenied
aws rds create-db-instance \
  --db-instance-identifier test-unenc \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password TestPass123 \
  --no-storage-encrypted \
  --allocated-storage 20

# Create with encryption — expect success
aws rds create-db-instance \
  --db-instance-identifier test-enc \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password TestPass123 \
  --storage-encrypted \
  --allocated-storage 20
```

## Exceptions and customisation
- Oracle licensing restrictions do not affect this policy — Oracle on RDS supports encryption.
- SQL Server Express and Web editions support encryption — they are included in the engine list.
- EFS encryption cannot be enabled after creation. Any existing unencrypted EFS must be migrated using AWS DataSync.

## References
- [AWS RDS encryption at rest](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)
- [AWS EFS encryption](https://docs.aws.amazon.com/efs/latest/ug/encryption-at-rest.html)
- [CIS AWS Foundations Benchmark — 2.3.1, 2.3.2](https://www.cisecurity.org/benchmark/amazon_web_services)
- [PCI-DSS v4.0 — Requirement 3.5](https://www.pcisecuritystandards.org/)
