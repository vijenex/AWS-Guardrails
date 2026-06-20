⚖ Contributing to AWS-Guardrails

Thank you for using this repo. Here is how
to submit improvements or new policies.

## Before you open a PR

Run the validation script locally:
  git clone https://github.com/vijenex/AWS-Guardrails
  cd AWS-Guardrails
  ./scripts/validate.sh

Fix any errors before submitting.

## Adding a new policy file

1. Choose the correct folder for your policy type:
     scp/              → Service Control Policies
     rcp/              → Resource Control Policies
     tag-policies/     → AWS Organizations tag policies
     backup-policies/  → AWS Backup policies
     declarative-policies/ → Declarative policies
     ai-opt-out-policies/  → AI service opt-out policies

2. Name the file descriptively:
     deny-root-account-usage.json
     enforce-s3-encryption.json
     restrict-approved-regions.json

3. Add the _meta block as the first key in the JSON

4. Create a companion [filename].md in the same
   folder — this is required and PRs without it
   will not be merged

5. Test the policy against a non-production AWS
   account before submitting — include the AWS
   Organizations policy type and the account/OU
   you tested against in your PR description

## Commit message format

  feat: add SCP to deny root account API calls
  fix: correct condition key in region restriction SCP
  docs: add companion doc for backup enforcement policy

## What gets rejected

- JSON files without a _meta block
- Policy files without a companion .md
- Policies with Effect: Allow and Action: *
- Untested policies (mention your test environment)
- Files with hardcoded account IDs or ARNs
  without a REPLACE_WITH_YOUR_VALUE comment

## Reporting a broken policy

Open an issue using the bug report template.
Include the exact error from AWS when you
applied the policy and the AWS Organizations
policy type.

## Attribution

By contributing you agree your submission
is licensed under Apache 2.0. The Vijenex™
trademark and brand assets are not covered
by this license and remain the exclusive
property of Vijenex™. Your contribution
will be credited in the git history.
