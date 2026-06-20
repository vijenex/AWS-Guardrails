# enforce-mandatory-tags

## What this does
Blocks creating EC2 instances, volumes, VPCs, subnets, NAT Gateways, security groups, ECS clusters, ElastiCache clusters, OpenSearch domains, Lambda functions, and load balancers unless mandatory tags are present in the request. Customize the required tag keys (`Owner`, `Env`, `Subcomponent`, `Created_By`) to match your organization's tag taxonomy.

## Why you need this
Untagged resources are the root cause of:
- **Cost attribution failures**: you cannot allocate costs to teams, products, or cost centers without tags.
- **Security blind spots**: an untagged EC2 instance has no owner — no one knows who to contact when it's flagged as suspicious.
- **Compliance gaps**: security frameworks require knowing who owns each resource and what environment it belongs to.
- **Zombie resources**: untagged resources are frequently forgotten, incurring cost long after their purpose ended.

AWS Tag Editor and AWS Config can help *detect* untagged resources, but this SCP *prevents* them from being created in the first place.

## Security impact if you don't apply this
- Resources without an `Owner` tag have no accountability — incidents involving them cannot be routed.
- Untagged resources that should be in `Env=dev` end up with production-level permissions because there is no automated enforcement.
- Cost anomaly detection is harder without consistent tagging.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This is a high-friction policy change. Any existing Terraform, CDK, or CloudFormation that creates resources without these tags will fail immediately after this SCP is applied. Do a full audit before applying.

**Step 1 — Sandbox**: Apply with your tag key list. Run your most common IaC scripts with and without tags. Fix all missing tags. This will likely take several days of engineering work.

**Step 2 — Non-production**: Run the full CI/CD pipeline. Fix every failing template, script, or automation. Communicate required tags to all developers. Apply only after 100% of non-prod automation passes.

**Step 3 — Production**: Apply during a change freeze. Have a rollback plan (detach the SCP) ready. Monitor for `AccessDenied` on `RunInstances`, `CreateVolume`, etc. for the first 24–48h.

**Vijenex is not responsible for IaC pipeline failures from applying this policy without completing the testing ladder.**

## Prerequisites
1. Define your required tag keys and communicate them org-wide.
2. Update all Terraform, CDK, CloudFormation, and scripts to include required tags on all resources.
3. Update any developer runbooks.

## How to apply
```bash
# Edit the JSON to match your required tag keys (replace "Owner", "Env", "Subcomponent", "Created_By")
aws organizations create-policy \
  --name "enforce-mandatory-tags" \
  --description "Block resource creation without mandatory tags" \
  --content file://enforce-mandatory-tags.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Create EC2 instance WITHOUT required tags — expect AccessDenied
aws ec2 run-instances \
  --image-id ami-REPLACE_YOUR_AMI \
  --instance-type t3.micro \
  --count 1

# Create WITH required tags — expect success
aws ec2 run-instances \
  --image-id ami-REPLACE_YOUR_AMI \
  --instance-type t3.micro \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Owner,Value=platform-team},{Key=Env,Value=dev},{Key=Subcomponent,Value=web},{Key=Created_By,Value=test-runner}]'
```

## Exceptions and customisation
- **Tag keys**: customize the `aws:RequestTag/<key>` keys to match your tag taxonomy.
- **Mandatory vs optional**: the `Null` condition blocks creation if the tag is absent. For a tag that must exist but can have any value, use `StringNotLike` with `*` to allow any non-empty value.
- **Ticket tag**: consider adding `aws:RequestTag/Ticket` for change management traceability in regulated environments.
- **Breaking existing automation**: do not add exceptions by principal ARN — fix the automation to include tags.

## References
- [AWS tagging best practices](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html)
- [AWS Tag Editor](https://docs.aws.amazon.com/tag-editor/latest/userguide/tagging.html)
- [AWS Config — required-tags rule](https://docs.aws.amazon.com/config/latest/developerguide/required-tags.html)
- [CIS AWS Foundations Benchmark — 3.14 (tagging for cost attribution)](https://www.cisecurity.org/benchmark/amazon_web_services)
