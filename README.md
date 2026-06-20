# Vijenex AWS Guardrails

**Production-tested AWS Organizations governance policies covering SCPs, RCPs, backup enforcement, tag compliance, declarative policies, and AI opt-out controls. Copy what you need. Read the companion docs before applying to production.**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Maintained by Vijenex™](https://img.shields.io/badge/Maintained_by-Vijenex™-green.svg)](https://vijenex.com)
[![Policies](https://img.shields.io/badge/Policies-37_JSON-orange.svg)](https://github.com/vijenex/AWS-Guardrails)
[![Policy Types](https://img.shields.io/badge/AWS_Policy_Types-6-purple.svg)](https://github.com/vijenex/AWS-Guardrails)

---

## Overview

Vijenex AWS Guardrails is a curated, open-source library of AWS Organizations governance policies covering all six AWS policy types: Service Control Policies (SCPs), Resource Control Policies (RCPs), Declarative Policies, Backup Policies, Tag Policies, and AI Opt-Out Policies.

Every policy in this library has been validated in real AWS Organizations environments. Each policy is self-contained, parameterized with clearly marked placeholders, and ships with a companion documentation file covering what it does, why it matters, what breaks without it, and how to test it safely.

**This is a reference library, not an automation tool.** You pick the policies you need, read the docs, customize the placeholders, test in sandbox, then deploy.

---

## Why this exists

Most AWS guardrail examples online are either:
- Too simple (a single deny-root-access with no context)
- Tied to a specific tool (Terraform modules, CDK constructs that add abstraction overhead)
- Incomplete (no documentation on what breaks, no testing guidance)

This library closes that gap. Each policy is a standalone JSON file that can be applied with the AWS CLI, AWS Console, Terraform, CDK, or any IaC tool. No framework dependency. No vendor lock-in.

---

## Policy types covered

AWS Organizations supports six distinct policy types. This library covers all of them.

| Policy Type | Description | Folder |
|---|---|---|
| **Service Control Policies (SCP)** | Restrict what IAM principals in your org can do | `scp/` |
| **Resource Control Policies (RCP)** | Restrict what can be done to your resources, regardless of caller | `rcp/` |
| **Declarative Policies** | Enforce EC2 configuration baseline account-wide | `declarative-policies/` |
| **Backup Policies** | Deploy AWS Backup plans automatically to all accounts | `backup-policies/` |
| **Tag Policies** | Enforce tag key capitalisation and allowed values | `tag-policies/` |
| **AI Opt-Out Policies** | Prevent AWS from using your data to improve AI models | `ai-opt-out-policies/` |

---

## SCP policy index

SCPs are organized by control domain.

### AI / Machine Learning

| Policy | What it does | Risk mitigated |
|---|---|---|
| [deny-bedrock-specific-models](scp/ai-ml/deny-bedrock-specific-models/) | Block specific Bedrock foundation model ARNs | Unauthorized use of expensive or unapproved AI models |
| [deny-bedrock-without-guardrail](scp/ai-ml/deny-bedrock-without-guardrail/) | Require a Bedrock Guardrail on all model invocations | Prompt injection, unfiltered AI output, compliance violations |
| [deny-amazon-q](scp/ai-ml/deny-amazon-q/) | Block Amazon Q and Q Developer entirely | Unapproved AI assistant accessing code and cloud environment |

### Compute

| Policy | What it does | Risk mitigated |
|---|---|---|
| [enforce-imdsv2](scp/compute/enforce-imdsv2/) | Block EC2 launches without IMDSv2 token requirement | SSRF-based EC2 credential theft via IMDSv1 |
| [deny-ec2-public-ip](scp/compute/deny-ec2-public-ip/) | Block launching EC2 instances with public IPs | Direct internet exposure of compute instances |
| [deny-community-amis](scp/compute/deny-community-amis/) | Block launching community (public marketplace) AMIs | Supply chain compromise via malicious or unvetted AMIs |
| [enforce-golden-ami](scp/compute/enforce-golden-ami/) | Restrict EC2 launches to an approved AMI allowlist | Configuration drift, unapproved base images |
| [deny-ec2-serial-console](scp/compute/deny-ec2-serial-console/) | Disable EC2 serial console access org-wide | Out-of-band OS-level access that bypasses IAM controls |
| [deny-ec2-import-export](scp/compute/deny-ec2-import-export/) | Block VM import and export operations | VM image exfiltration and unauthorized image import |
| [deny-ebs-encryption-disable](scp/compute/deny-ebs-encryption-disable/) | Prevent disabling EBS default encryption account-wide | Newly created volumes that bypass encryption |
| [deny-unencrypted-ebs-volumes](scp/compute/deny-unencrypted-ebs-volumes/) | Block attaching and snapshotting unencrypted EBS volumes | Data at rest exposure, unencrypted snapshot sharing |

### Cost Governance

| Policy | What it does | Risk mitigated |
|---|---|---|
| [resource-deletion-protection](scp/cost-governance/resource-deletion-protection/) | Block deletion of critical production infrastructure | Cloud ransomware, accidental or malicious infrastructure destruction |
| [enforce-mandatory-tags](scp/cost-governance/enforce-mandatory-tags/) | Block creating key resources without required tags | Cost attribution failures, unowned orphaned resources |
| [secrets-manager-hardening](scp/cost-governance/secrets-manager-hardening/) | Require owner tags on all Secrets Manager secrets | Orphaned secrets, untracked credentials |

### Database

| Policy | What it does | Risk mitigated |
|---|---|---|
| [deny-unencrypted-rds](scp/database/deny-unencrypted-rds/) | Block creating unencrypted RDS, Aurora, and EFS | Database plaintext at rest, unencrypted snapshot sharing |
| [restrict-multiaz](scp/database/restrict-multiaz/) | Block Multi-AZ RDS and ElastiCache in non-production OUs | Unnecessary spend in development and sandbox accounts |

### Governance

| Policy | What it does | Risk mitigated |
|---|---|---|
| [deny-org-leave](scp/governance/deny-org-leave/) | Block leaving org, account closure, and external RAM shares | Account escaping from org governance controls |
| [protect-org-structure](scp/governance/protect-org-structure/) | Protect OU hierarchy, directories, and core networking | Destruction of the governance inheritance chain |
| [deny-aws-marketplace](scp/governance/deny-aws-marketplace/) | Block all AWS Marketplace software procurement | Unauthorized third-party software and SaaS spend |

### IAM

| Policy | What it does | Risk mitigated |
|---|---|---|
| [deny-root-access](scp/iam/deny-root-access/) | Block all API activity performed by the root user | Root credential compromise, accidental root usage |
| [deny-admin-access-policies](scp/iam/deny-admin-access-policies/) | Block attaching AdministratorAccess and FullAccess managed policies | Privilege escalation via overly broad managed policies |
| [deny-chatbot-iam](scp/iam/deny-chatbot-iam/) | Block IAM mutations triggered from AWS Chatbot | Chat-based privilege escalation via Slack or Teams |
| [deny-iam-access-keys](scp/iam/deny-iam-access-keys/) | Block creating IAM user access keys | Long-lived credential exposure and secrets sprawl |

### Networking

| Policy | What it does | Risk mitigated |
|---|---|---|
| [deny-vpc-peering](scp/networking/deny-vpc-peering/) | Block all VPC peering operations | Unauthorized cross-account network access |
| [deny-cloudfront-without-https](scp/networking/deny-cloudfront-without-https/) | Block CloudFront distributions without HTTPS enforcement | Man-in-the-middle, session hijacking over HTTP |
| [restrict-regions](scp/networking/restrict-regions/) | Restrict resource creation to approved AWS regions | Data residency violations, uncontrolled region sprawl |

### Security Services

| Policy | What it does | Risk mitigated |
|---|---|---|
| [protect-security-services](scp/security-services/protect-security-services/) | Protect GuardDuty, CloudTrail, Config, Security Hub | Attackers disabling detection before a strike |
| [protect-controltower](scp/security-services/protect-controltower/) | Protect all AWS Control Tower managed resources | Control Tower governance infrastructure destruction |
| [deny-ssm-unprivileged-roles](scp/security-services/deny-ssm-unprivileged-roles/) | Block SSM Session Manager for read-only SSO roles | Privilege escalation from read-only access to shell |

### Storage

| Policy | What it does | Risk mitigated |
|---|---|---|
| [s3-hardening](scp/storage/s3-hardening/) | Block S3 website hosting, enforce bucket-owner-enforced ACL mode | S3 data exposure via website endpoints, ACL bypass |
| [deny-s3-public-access-modification](scp/storage/deny-s3-public-access-modification/) | Lock the S3 Block Public Access setting | Unauthorized bucket exposure by disabling the block |

---

## RCP policy index

Resource Control Policies restrict what can be done **to** your resources, including from outside your organization.

| Policy | What it does |
|---|---|
| [deny-s3-public-access](rcp/storage/deny-s3-public-access/) | Block any principal from disabling Block Public Access on your S3 buckets |
| [deny-cross-org-assume-role](rcp/iam/deny-cross-org-assume-role/) | Block any principal outside your org from assuming IAM roles |

---

## Other policy types

| Policy | Type | What it does |
|---|---|---|
| [enforce-imdsv2-declarative](declarative-policies/ec2/) | Declarative Policy | Enforce IMDSv2 and hop limit 1 on all EC2 instances account-wide |
| [enforce-backup-plan](backup-policies/) | Backup Policy | Deploy daily + weekly backup plans to all accounts automatically |
| [enforce-resource-tagging](tag-policies/) | Tag Policy | Enforce Environment, Owner, CostCenter tag standards |
| [deny-ai-service-data-sharing](ai-opt-out-policies/) | AI Opt-Out Policy | Opt all accounts out of AWS AI service data sharing |

---

## Prerequisites

Before applying any policy from this library:

- **AWS Organizations** with the relevant policy type enabled
- **IAM permissions**: `organizations:CreatePolicy`, `organizations:AttachPolicy`, `organizations:EnablePolicyType`
- **Tested AWS CLI or IaC tooling** configured with appropriate credentials
- **Read the companion `.md`** for every policy you intend to apply — it lists customization requirements, known exceptions, and testing steps

---

## How to apply a policy

### Enable a policy type (one-time per org)
```bash
aws organizations enable-policy-type \
  --root-id $(aws organizations list-roots --query 'Roots[0].Id' --output text) \
  --policy-type SERVICE_CONTROL_POLICY
```

### Create and attach a policy
```bash
# Create
POLICY_ID=$(aws organizations create-policy \
  --name "deny-root-access" \
  --description "Block all root user API activity across the org" \
  --content file://scp/iam/deny-root-access/deny-root-access.json \
  --type SERVICE_CONTROL_POLICY \
  --query Policy.PolicySummary.Id \
  --output text)

# Attach to an OU
aws organizations attach-policy \
  --policy-id $POLICY_ID \
  --target-id ou-REPLACE_WITH_YOUR_OU_ID
```

### Validate before deploying
```bash
git clone https://github.com/vijenex/AWS-Guardrails.git
cd AWS-Guardrails
./scripts/validate.sh
```

---

## Testing ladder

Every policy in this library must follow this sequence before reaching production:

| Stage | Purpose | Actions |
|---|---|---|
| **Sandbox** | Verify the policy enforces what it claims | Apply, attempt the blocked action, confirm denial |
| **Non-production** | Verify no automation or tooling breaks | Monitor CI/CD pipelines, Lambda functions, deployment roles |
| **Production** | Apply in a maintenance window | Monitor for 24–48 hours, have a rollback plan ready |

**SCPs take effect immediately with no built-in rollback.** The only rollback is detaching the policy. Always test before attaching at a wide scope.

> **Vijenex is not responsible for any accidental policy applied directly in production. All policies must be tested in sandbox and non-production environments before production deployment.**

---

## Policy structure

Every policy JSON in this library follows this structure:

```json
{
  "_meta": {
    "source": "https://github.com/vijenex/AWS-Guardrails",
    "author": "Vijenex™ — https://vijenex.com",
    "license": "Apache-2.0",
    "description": "Short description of what this policy does",
    "protects_against": "What threat or risk this policy mitigates",
    "last_validated": "YYYY-MM"
  },
  "Version": "2012-10-17",
  "Statement": [...]
}
```

Policies with required customization use clearly marked `REPLACE_*` placeholders. The validation script will warn you if any are left unfilled.

---

## Validation

```bash
./scripts/validate.sh              # validate all policies
./scripts/validate.sh scp/iam/     # validate a specific subfolder
```

Checks performed:
- JSON syntax validity
- `_meta` header present in every file
- No hardcoded AWS account IDs (12-digit numbers)
- No hardcoded AWS organization IDs (`o-xxxxxxxxxx`)
- Warns on any unfilled `REPLACE_*` placeholders
- Warns if a companion `.md` file is missing

---

## Compliance mapping

Policies in this library address controls from:

- **CIS AWS Foundations Benchmark** (v1.5 / v2.0)
- **AWS Security Hub FSBP** (Foundational Security Best Practices)
- **NIST SP 800-53** (access control, audit, configuration management)
- **PCI-DSS** (network segmentation, encryption, access restriction)
- **HIPAA** (data protection, access controls, audit logging)
- **SOC 2** (availability, confidentiality, security controls)
- **MITRE ATT&CK** (cloud-specific technique mitigations)

Specific framework references are listed in each policy's companion `.md`.

---

## Repository structure

```
AWS-Guardrails/
├── scp/
│   ├── ai-ml/
│   ├── compute/
│   ├── cost-governance/
│   ├── database/
│   ├── governance/
│   ├── iam/
│   ├── networking/
│   ├── security-services/
│   └── storage/
├── rcp/
│   ├── iam/
│   └── storage/
├── declarative-policies/
│   └── ec2/
├── backup-policies/
├── tag-policies/
├── ai-opt-out-policies/
└── scripts/
    └── validate.sh
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

Requirements for all submissions:
- Policy JSON must include a `_meta` header block
- No hardcoded account IDs, org IDs, role names, or company-specific values
- All sensitive values must use `REPLACE_*` placeholders
- A companion `.md` file is mandatory — submissions without documentation will not be accepted
- Policy must be tested before submission

Security disclosures: **security@vijenex.com**

---

## License

Apache License 2.0. See [LICENSE](LICENSE).

You may use, modify, and distribute any file in this repository. The Vijenex™ name and logo may not be removed from file headers or used to represent a derivative project.

---

Maintained by [Vijenex™](https://vijenex.com)
