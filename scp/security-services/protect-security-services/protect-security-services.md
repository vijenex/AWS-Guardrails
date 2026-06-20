# protect-security-services

## What this does
Locks in AWS security monitoring services: blocks disabling or deleting CloudTrail trails, GuardDuty detectors/members, Security Hub, AWS Config recorders, IAM Access Analyzer, and EC2 public image/snapshot block settings. These services remain active even if an attacker or insider attempts to disable them.

## Why you need this
Disabling security monitoring is a standard attacker technique documented in MITRE ATT&CK (T1562 Impair Defenses). Before executing their primary objective, attackers with compromised credentials routinely:
1. Stop CloudTrail to erase their tracks going forward
2. Disable GuardDuty to prevent real-time threat detection
3. Modify Config to stop compliance recording

This SCP makes those actions impossible even for users with broad IAM permissions, because SCPs override IAM. The security monitoring infrastructure is protected at the governance layer.

## Security impact if you don't apply this
- Attacker disables CloudTrail → no audit trail of further actions → forensic investigation becomes impossible.
- Attacker disables GuardDuty → all threat intelligence detections stop → unauthorized activity is not alerted on.
- MITRE ATT&CK T1562.008 specifically targets cloud security service disruption as a pre-attack step.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This policy prevents your own security team from modifying these services via API/CLI. Any legitimate updates to CloudTrail, GuardDuty, or Config must go through the management account or an excluded OU.

**Step 1 — Sandbox**: Apply and verify `cloudtrail:StopLogging` and `guardduty:DeleteDetector` return `AccessDenied`.

**Step 2 — Non-production**: Verify all automated security operations (e.g., Control Tower account vending, Security Hub automation) still function. Some automation modifies these services during account setup — it should run from the management account, not member accounts.

**Step 3 — Production**: Apply. This is a high-value, low-risk policy for production. Monitor CloudTrail for `AccessDenied` events from legitimate security tooling that needs exemption.

**Vijenex is not responsible for security operations disruption from applying this policy.**

## How to apply
```bash
aws organizations create-policy \
  --name "protect-security-services" \
  --description "Prevent disabling GuardDuty, CloudTrail, Security Hub, and Config" \
  --content file://protect-security-services.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to stop CloudTrail logging — expect AccessDenied
aws cloudtrail stop-logging --name REPLACE_TRAIL_NAME

# Attempt to delete GuardDuty detector — expect AccessDenied
aws guardduty delete-detector --detector-id REPLACE_DETECTOR_ID
```

## Exceptions and customisation
- If Control Tower or Landing Zone automation modifies these services during account vending, run it from the management account (excluded from SCPs) rather than adding exceptions.
- If you need to allow specific security roles to update Config rules (not disable them), scope the Config deny to only `DeleteConfigurationRecorder` and `StopConfigurationRecorder`, not `PutConfigRule`.

## References
- [MITRE ATT&CK — T1562 Impair Defenses](https://attack.mitre.org/techniques/T1562/)
- [MITRE ATT&CK — T1562.008 Disable Cloud Logs](https://attack.mitre.org/techniques/T1562/008/)
- [AWS Security Blog — Protecting CloudTrail](https://aws.amazon.com/blogs/security/)
- [CIS AWS Foundations Benchmark — 3.1 (CloudTrail), 3.2 (multi-region CloudTrail)](https://www.cisecurity.org/benchmark/amazon_web_services)
