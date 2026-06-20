# deny-bedrock-without-guardrail

## What this does
Blocks all Amazon Bedrock model invocations unless the request includes an approved Guardrail identifier. Any `InvokeModel` or `InvokeModelWithResponseStream` call that does not pass the correct `bedrock:GuardrailIdentifier` condition is denied.

## Why you need this
Amazon Bedrock Guardrails provide content filtering, topic blocking, PII detection, and prompt attack mitigation. Without enforcement at the SCP layer, developers can call Bedrock models directly without any guardrail — leaving your AI workloads exposed to:
- Prompt injection attacks that exfiltrate data or bypass application logic
- Toxic or harmful content returned to end users
- Unintentional disclosure of PII processed by the model

This SCP makes guardrail enforcement non-optional at the infrastructure layer, so application-level bugs or shortcuts cannot remove the protection.

## When to apply this
- Apply to any OU running production AI workloads where content filtering is a compliance or safety requirement.
- Do **not** apply to research/experimentation OUs where developers need to test models without guardrails.
- You need a Guardrail already created in your account before applying this policy.

## Prerequisites
1. Create a Bedrock Guardrail in the target account/region:
   ```bash
   aws bedrock create-guardrail \
     --name "my-approved-guardrail" \
     --blocked-input-messaging "This request was blocked." \
     --blocked-outputs-messaging "This response was blocked." \
     --region ap-south-1
   ```
2. Note the returned Guardrail ARN — it looks like:
   `arn:aws:bedrock:ap-south-1:123456789012:guardrail/GUARDRAILID:VERSION`
3. Replace `REPLACE_WITH_YOUR_GUARDRAIL_ARN` in the policy JSON with that ARN.

## How to apply
```bash
# After editing the JSON with your Guardrail ARN:
aws organizations create-policy \
  --name "deny-bedrock-without-guardrail" \
  --description "Require approved Bedrock Guardrail on all model invocations" \
  --content file://deny-bedrock-without-guardrail.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Call WITHOUT guardrail — expect AccessDenied
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-sonnet-4-6 \
  --body '{"anthropic_version":"bedrock-2023-05-31","messages":[{"role":"user","content":"hello"}],"max_tokens":10}' \
  output.json

# Call WITH correct guardrail — expect success
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-sonnet-4-6 \
  --guardrail-identifier REPLACE_WITH_YOUR_GUARDRAIL_ID \
  --guardrail-version DRAFT \
  --body '{"anthropic_version":"bedrock-2023-05-31","messages":[{"role":"user","content":"hello"}],"max_tokens":10}' \
  output.json
```

## Exceptions and customisation
- To allow multiple guardrails, change `StringNotEquals` to `StringNotEqualsIfExists` and provide a list:
  ```json
  "StringNotEqualsIfExists": {
    "bedrock:GuardrailIdentifier": [
      "arn:aws:bedrock:...:guardrail/ID1:1",
      "arn:aws:bedrock:...:guardrail/ID2:1"
    ]
  }
  ```
- Guardrail ARNs include the version number (`...guardrail/ID:1`). Update the ARN when you publish a new guardrail version.

## References
- [Amazon Bedrock Guardrails overview](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)
- [SCP condition key: bedrock:GuardrailIdentifier](https://docs.aws.amazon.com/bedrock/latest/userguide/security_iam_service-with-iam.html)
- [OWASP Top 10 for LLM — LLM01 Prompt Injection](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
