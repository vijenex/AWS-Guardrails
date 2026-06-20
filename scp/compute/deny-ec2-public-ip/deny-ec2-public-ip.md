# deny-ec2-public-ip

## What this does
Blocks `ec2:RunInstances` whenever the launch request includes `AssociatePublicIpAddress: true`. Instances can only be launched into private subnets or subnets that do not auto-assign public IPs.

## Why you need this
A public IP address makes an EC2 instance directly reachable from the internet. Even with security groups, every port scan, brute-force attempt, and vulnerability scanner on the internet can reach the instance. Cloud instances with direct public IPs are one of the most common initial access vectors in cloud incident reports.

Workloads that need internet access should go through a NAT Gateway or use AWS PrivateLink. Only load balancers should have public-facing IPs, and ALBs/NLBs have a separate creation path not blocked by this policy.

## When to apply this
- Apply to all production and staging OUs.
- Apply to developer OUs where VPN or AWS Client VPN provides private access.
- Do **not** apply if your workload explicitly requires direct internet-facing EC2 instances (rare, and usually an architecture problem).

## Prerequisites
- A NAT Gateway or NAT instance in a public subnet for outbound internet access.
- Or AWS Client VPN / Site-to-Site VPN for developer access.
- Subnets must have `MapPublicIpOnLaunch` set to `false` for the SCP to be necessary — but the SCP adds defense-in-depth if subnet settings are accidentally changed.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-ec2-public-ip" \
  --description "Block launching EC2 instances with public IP addresses" \
  --content file://deny-ec2-public-ip.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to launch with public IP — expect AccessDenied
aws ec2 run-instances \
  --image-id ami-REPLACE_WITH_YOUR_AMI \
  --instance-type t3.micro \
  --network-interfaces '[{"DeviceIndex":0,"AssociatePublicIpAddress":true,"SubnetId":"subnet-REPLACE"}]'

# Launch into private subnet (no AssociatePublicIpAddress) — expect success
aws ec2 run-instances \
  --image-id ami-REPLACE_WITH_YOUR_AMI \
  --instance-type t3.micro \
  --subnet-id subnet-REPLACE_PRIVATE_SUBNET
```

## Exceptions and customisation
- Bastion hosts in a public subnet: use AWS Systems Manager Session Manager instead — it eliminates the need for a public bastion entirely.
- If you genuinely need one public EC2 instance (rare), do it via the console (not API) and ensure it is in a dedicated OU not covered by this SCP.
- This policy does not prevent associating an Elastic IP to an already-running instance. Pair with `ec2:AssociateAddress` deny if needed.

## References
- [AWS — Instances with public IP addresses (AWS Config rule)](https://docs.aws.amazon.com/config/latest/developerguide/ec2-instance-no-public-ip.html)
- [AWS Well-Architected — Network protection](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/protecting-networks.html)
- [NIST SP 800-190 — Container security guide (surface reduction)](https://csrc.nist.gov/publications/detail/sp/800-190/final)
