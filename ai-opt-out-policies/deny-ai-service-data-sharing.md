# AI Opt-Out Policy: deny-ai-service-data-sharing

## What this does
An **AWS Organizations AI Opt-Out Policy** that opts all accounts in the attached scope out of AWS's AI service data-sharing programs. By default, AWS may use content processed by some AI services to improve those services. This policy enforces `optOut` for:

- **Amazon Rekognition** — image/video analysis
- **Amazon Textract** — document OCR
- **Amazon Comprehend** — NLP/entity extraction
- **Amazon Translate** — language translation
- **Amazon Polly** — text-to-speech
- **Amazon Transcribe** — speech-to-text
- **Amazon Lex** — chatbots/conversational AI
- **Amazon Personalize** — recommendation models
- **Amazon Forecast** — time-series forecasting
- **Amazon CodeGuru Profiler** — application profiling
- **Amazon CodeWhisperer / Q Developer** — AI code suggestions

`@@operators_allowed_for_child_policies: ["@@none"]` prevents any child OU or account from opting back in — the opt-out is mandatory.

## Why you need this
When you send data to AWS AI services (documents, images, audio, code), that data may be stored and used to retrain AWS AI models unless you explicitly opt out. For regulated industries (healthcare, financial services, legal) or for organisations handling PII, confidential IP, or customer data, this is a compliance and privacy requirement.

> **By default, if you do NOT apply this policy, your data may be used to improve AWS AI services.**

## Security impact if you don't apply this
- **Data leakage**: Customer PII processed by Rekognition (e.g., ID document verification) or Transcribe (e.g., call centre recordings) may be retained and used by AWS for model training.
- **IP exposure**: Code processed by CodeWhisperer may be used to improve suggestions for other users.
- **GDPR / HIPAA compliance failure**: Processing personal data in AI services without data processing agreements and explicit opt-out mechanisms may violate data residency requirements.
- **Trust risk**: Customers assume their data is not used for third-party model training. Failing to opt out breaks that assumption.

## ⚠️ Disclaimer
> **Vijenex is not responsible for any accidental policy applied directly in production.**
>
> AI Opt-Out Policies require the policy type to be enabled in your org. Test in a sandbox OU before applying to the org root. This policy does NOT affect AI service functionality — it only affects AWS's use of your data for model improvement.

## Testing ladder
1. **Sandbox**: Attach to a sandbox OU. Verify the effective policy via `aws organizations describe-effective-policy --policy-type AISERVICES_OPT_OUT_POLICY`. Confirm `optOut` appears for each service.
2. **Non-production**: Apply to dev/staging OUs. No functional change expected — AI services continue working normally.
3. **Production**: Apply at root or target OUs. This change is low-risk from an operational standpoint but high-impact from a compliance standpoint.

## Prerequisites
- Enable AI Opt-Out Policies in your org: `aws organizations enable-policy-type --root-id r-XXXX --policy-type AISERVICES_OPT_OUT_POLICY`
- No other prerequisites — this policy does not affect service functionality.

## How to apply
```bash
# Enable AI Opt-Out Policies in your org (one-time)
aws organizations enable-policy-type \
  --root-id r-REPLACE_ORG_ROOT \
  --policy-type AISERVICES_OPT_OUT_POLICY

# Create the policy
aws organizations create-policy \
  --name "deny-ai-service-data-sharing" \
  --content file://deny-ai-service-data-sharing.json \
  --type AISERVICES_OPT_OUT_POLICY

# Attach to OU or root
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id r-REPLACE_ORG_ROOT
```

## How to test
```bash
# Verify effective policy on an account
aws organizations describe-effective-policy \
  --policy-type AISERVICES_OPT_OUT_POLICY \
  --target-id REPLACE_ACCOUNT_ID

# The response should show optOut for each service listed in the policy
```

## Exceptions and customization
- To allow certain accounts to opt back in (e.g., an R&D account contributing to model research), create a child OU with `@@operators_allowed_for_child_policies: ["@@assign"]` and override to `optIn`.
- Remove individual services from the policy if your organisation has a specific approved data-sharing agreement with AWS for that service.

## References
- [AWS Organizations AI Opt-Out Policies documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html)
- [AWS AI service data usage FAQ](https://aws.amazon.com/machine-learning/faqs/)
- [AWS GDPR Centre](https://aws.amazon.com/compliance/gdpr-center/)
