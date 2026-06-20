# deny-bedrock-specific-models

## What this does
Blocks invocation of specific Amazon Bedrock foundation models by their exact ARN. Applies to direct invocation, streaming invocation, and batch inference jobs. Customize the `Resource` list to match the models you want to block in your environment.

## Why you need this
Without model-level access control, any principal with `bedrock:InvokeModel` can invoke the most expensive or most capable models in Bedrock. This creates two risks:
1. **Cost exposure** — high-capability models (e.g., Claude Opus, Claude Fable 5) cost significantly more per token than lighter models. A misconfigured agent or a developer testing against prod can generate thousands of dollars of spend in hours.
2. **Governance risk** — some organizations require formal approval before deploying specific AI models in production (data classification, model cards, security review). This SCP enforces that gate at the infrastructure layer.

## When to apply this
- Apply to developer, sandbox, and non-production OUs where heavy/expensive models are not approved.
- Do **not** apply broadly if your production workload legitimately requires the blocked models — use it surgically by OU.
- Update the `Resource` ARN list as new Bedrock models are released and as your approved model list evolves.

## Prerequisites
- Amazon Bedrock must be enabled in the account region.
- Review which model ARNs are in use with: `aws bedrock list-foundation-models --region us-east-1`

## How to apply
```bash
# Edit the Resource list in the JSON file to match models you want to block
# Then create and attach the SCP:

aws organizations create-policy \
  --name "deny-bedrock-specific-models" \
  --description "Block invocation of specific unapproved Bedrock models" \
  --content file://deny-bedrock-specific-models.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to invoke a blocked model — expect AccessDenied
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-fable-5 \
  --body '{"anthropic_version":"bedrock-2023-05-31","messages":[{"role":"user","content":"hi"}],"max_tokens":10}' \
  --region us-east-1 \
  output.json
```
Expected: `AccessDenied` error.

## Exceptions and customisation
- **To block different models**: replace or add ARNs in the `Resource` array. Find model ARNs in the Bedrock console or via `aws bedrock list-foundation-models`.
- **Cross-region inference profiles**: models accessed via inference profiles use the `inference-profile` ARN pattern — include both the `foundation-model` and `inference-profile` ARNs to fully block a model.
- Do not add `NotPrincipal` exceptions — use a separate permissive policy attached at a lower OU level for teams with approval.

## References
- [Amazon Bedrock model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
- [Amazon Bedrock cross-region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles.html)
- [AWS SCP best practices — service-level guardrails](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_best-practices.html)
