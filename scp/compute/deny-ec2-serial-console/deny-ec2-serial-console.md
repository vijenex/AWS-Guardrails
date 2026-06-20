# deny-ec2-serial-console

## What this does
Prevents EC2 serial console access from being enabled at the account level. If serial console is already enabled, this stops it being re-enabled after disable.

## Why you need this
EC2 serial console provides direct OS-level shell access to an instance without requiring the instance to have a network connection, running SSH, or any security agent installed. It bypasses:
- Security groups
- NACLs
- SSM access controls
- Host-based firewalls

An attacker or insider with IAM permissions to `ec2:EnableSerialConsoleAccess` and `ec2-instance-connect:SendSerialConsoleSSHPublicKey` can access any instance in the account at the OS level, regardless of what other network security controls are in place.

In production environments, the legitimate use cases for serial console (debugging a broken OS, recovering a locked-out instance) can be handled through a documented break-glass process with controlled IAM access.

## When to apply this
Apply to all production, pre-production, and staging OUs. Apply to any OU where you want to ensure that instance access is always through SSM Session Manager or SSH with proper key management.

## Prerequisites
- Disable serial console in existing accounts first:
  ```bash
  aws ec2 disable-serial-console-access --region REPLACE_WITH_YOUR_REGION
  ```
- Ensure your operational runbook for "broken instance recovery" uses AMI-based restore, not serial console.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-ec2-serial-console" \
  --description "Block enabling EC2 serial console access" \
  --content file://deny-ec2-serial-console.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to enable serial console — expect AccessDenied
aws ec2 enable-serial-console-access --region REPLACE_WITH_YOUR_REGION
```

## Exceptions and customisation
No exceptions are recommended. If a break-glass serial console capability is required, create a dedicated break-glass OU that is excluded from this SCP, with full audit logging of all activity in that OU.

## References
- [AWS EC2 Serial Console documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-serial-console.html)
- [AWS — Replace serial console access with SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
