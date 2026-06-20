# deny-ec2-import-export

## What this does
Blocks all VM import and export operations for EC2: exporting instance images to S3 as VM files, importing external VMs into AWS, and importing snapshots or volumes from external sources.

## Why you need this
EC2 VM export (`CreateInstanceExportTask`, `ExportImage`) creates a complete disk image of a running instance including its OS, application data, and any credentials or secrets stored on disk. This image is written to an S3 bucket as a standard OVA/VMDK/VHD file and can then be downloaded.

This is one of the highest-impact data exfiltration vectors in AWS: a compromised IAM credential with EC2 and S3 permissions can use VM export to extract the full contents of any instance in minutes, bypassing any application-layer or database-layer access controls.

VM import is the inverse risk: an attacker with import permissions can bring a pre-backdoored VM image into your environment.

## When to apply this
Apply to all OUs. VM import/export is almost never part of normal application operations — it belongs in a specific migration or tooling OU with tight controls, not in production.

Legitimate use cases (cloud migration projects, VM-based software delivery) should be handled in a dedicated migration account that is explicitly excluded from this policy.

## Prerequisites
No prerequisites. This policy can be applied immediately without operational impact in accounts that do not perform VM import/export.

Check for in-flight import/export tasks before applying:
```bash
aws ec2 describe-export-tasks --region REPLACE_WITH_YOUR_REGION
aws ec2 describe-import-image-tasks --region REPLACE_WITH_YOUR_REGION
```

## How to apply
```bash
aws organizations create-policy \
  --name "deny-ec2-import-export" \
  --description "Block EC2 VM import and export operations" \
  --content file://deny-ec2-import-export.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to start an export — expect AccessDenied
aws ec2 create-instance-export-task \
  --instance-id i-REPLACE_WITH_ANY_INSTANCE_ID \
  --target-environment vmware \
  --export-to-s3-task DiskImageFormat=VMDK,ContainerFormat=OVA,S3Bucket=REPLACE_BUCKET
```

## Exceptions and customisation
No exceptions recommended in production. If you are running a cloud migration project, create a dedicated migration OU that excludes this SCP and apply tight time-bound credentials to it.

## References
- [AWS — VM Import/Export documentation](https://docs.aws.amazon.com/vm-import/latest/userguide/what-is-vmimport.html)
- [MITRE ATT&CK — T1537 Transfer Data to Cloud Account](https://attack.mitre.org/techniques/T1537/)
- [AWS Security Blog — Data exfiltration through EC2 export](https://aws.amazon.com/blogs/security/)
