#!/usr/bin/env bash
# Removes everything deploy.sh created: empties the bucket, then deletes the stack.
set -euo pipefail

STACK_NAME="${STACK_NAME:-referee-call-trainer}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"

BUCKET="$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)"
aws s3 rm "s3://$BUCKET" --recursive --region "$REGION"
aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK_NAME"
aws cloudformation wait stack-delete-complete --region "$REGION" --stack-name "$STACK_NAME"
echo "Deleted stack $STACK_NAME"
