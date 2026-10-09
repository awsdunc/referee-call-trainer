#!/usr/bin/env bash
# Deploys site/ to AWS: creates (or updates) the S3 + CloudFront stack, uploads the
# page, and clears the CloudFront cache. Needs the AWS CLI v2 signed in to your account.
set -euo pipefail

STACK_NAME="${STACK_NAME:-referee-call-trainer}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$HERE/../../site"

aws cloudformation deploy \
  --region "$REGION" \
  --stack-name "$STACK_NAME" \
  --template-file "$HERE/template.yaml" \
  --no-fail-on-empty-changeset

output() {
  aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}
BUCKET="$(output BucketName)"
DIST_ID="$(output DistributionId)"
URL="$(output SiteUrl)"

aws s3 sync "$SITE_DIR" "s3://$BUCKET" --region "$REGION" --delete \
  --cache-control "public, max-age=300"

aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*" >/dev/null

echo "Deployed: $URL"
