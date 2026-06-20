#!/usr/bin/env bash
# ─────────────────────────────────────────────
# Source:    https://github.com/vijenex/AWS-Guardrails
# Author:    Vijenex™ — https://vijenex.com
# License:   Apache-2.0
# Purpose:   Validate all policy files locally
#            before opening a pull request
# ─────────────────────────────────────────────

set -e

TARGET="${1:-.}"
PASS=0
FAIL=0

echo ""
echo "⚖  Vijenex AWS-Guardrails — Policy Validator"
echo "─────────────────────────────────────────────"
echo ""

# JSON syntax check
echo "› Checking JSON syntax..."
for f in $(find "$TARGET" -name "*.json" \
  -not -path "./.git/*"); do
  if python3 -m json.tool "$f" > /dev/null 2>&1
  then
    echo "  ✓ $f"
    PASS=$((PASS + 1))
  else
    echo "  ✗ INVALID: $f"
    FAIL=$((FAIL + 1))
  fi
done

# _meta block check
echo ""
echo "› Checking _meta attribution blocks..."
for f in $(find "$TARGET" -name "*.json" \
  -not -path "./.git/*"); do
  result=$(python3 -c "
import json, sys
try:
    data = json.load(open('$f'))
    if '_meta' not in data:
        print('MISSING')
    elif 'vijenex' not in \
      data['_meta'].get('source','').lower():
        print('NO_ATTRIBUTION')
    else:
        print('OK')
except:
    print('ERROR')
" 2>/dev/null)
  if [ "$result" = "OK" ]; then
    echo "  ✓ $f"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $result: $f"
    FAIL=$((FAIL + 1))
  fi
done

# Companion doc check
echo ""
echo "› Checking companion .md files..."
for f in $(find "$TARGET" -name "*.json" \
  -not -path "./.git/*"); do
  md="${f%.json}.md"
  if [ -f "$md" ]; then
    echo "  ✓ $md"
    PASS=$((PASS + 1))
  else
    echo "  ✗ MISSING: $md"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "─────────────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
  echo "Fix the issues above before opening a PR."
  exit 1
else
  echo "All checks passed. Ready to submit."
  exit 0
fi
