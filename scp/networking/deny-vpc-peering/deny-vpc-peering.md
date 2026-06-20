# deny-vpc-peering

## What this does
Blocks all VPC peering operations: creating peering connections, accepting inbound requests, deleting connections, and modifying peering options. Also blocks Transit Gateway peering attachment creation and acceptance for cross-region/cross-account TGW peering.

## Why you need this
VPC peering creates direct non-transitive network paths between VPCs. In a multi-account AWS organization, uncontrolled peering creates a web of trust relationships that:
- Are hard to audit — there is no central map of all peering connections across hundreds of accounts
- Enable lateral movement: a compromised account can peer with your production VPC if the production account accepts
- Bypass network segmentation: sandbox environments should not be able to peer with production, but without an SCP there is nothing stopping it

The recommended architecture is hub-and-spoke via AWS Transit Gateway, managed centrally by the networking team. This gives a single point of control and visibility for all cross-VPC routing.

## Security impact if you don't apply this
- Any account owner can initiate peering with any other account they have an account ID for.
- Sandbox environments can gain network access to production VPCs if a production account admin accidentally accepts a peering request.
- Lateral movement after account compromise is significantly easier with an existing peering connection.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: If existing VPC peering connections are in use for production traffic, applying this policy does NOT delete those connections — but new peering or modification will be blocked. Verify your architecture does not depend on new peering operations before applying.

**Step 1 — Sandbox**: Apply and verify `ec2:CreateVpcPeeringConnection` returns `AccessDenied`.

**Step 2 — Non-production**: Inventory existing peering connections (`aws ec2 describe-vpc-peering-connections`). Confirm they are not being newly created or modified. Apply and monitor for `AccessDenied`.

**Step 3 — Production**: Apply. Monitor for 24h. Verify Transit Gateway continues to function (TGW attachments to VPCs within the same account are not blocked — only cross-account/cross-region TGW peering is).

**Vijenex is not responsible for network connectivity disruptions from applying this policy.**

## Prerequisites
- Migrate cross-VPC traffic to AWS Transit Gateway before applying.
- Inventory existing peering connections: `aws ec2 describe-vpc-peering-connections --filters "Name=status-code,Values=active"`

## How to apply
```bash
aws organizations create-policy \
  --name "deny-vpc-peering" \
  --description "Block all VPC peering operations" \
  --content file://deny-vpc-peering.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to create peering — expect AccessDenied
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-REPLACE_YOUR_VPC \
  --peer-vpc-id vpc-REPLACE_PEER_VPC \
  --peer-region ap-south-1
```

## Exceptions and customisation
To allow peering between specific account pairs while blocking all others, use a condition:
```json
"Condition": {
  "StringNotEquals": {
    "aws:RequestedRegion": "REPLACE_WITH_YOUR_REGION"
  }
}
```
Or more precisely, exclude specific trusted accounts using `ArnNotLike` on `aws:PrincipalArn` for the specific networking admin role.

## References
- [AWS VPC Peering overview](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)
- [AWS Transit Gateway — hub and spoke architecture](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started.html)
- [MITRE ATT&CK — T1599 Network Boundary Bridging](https://attack.mitre.org/techniques/T1599/)
