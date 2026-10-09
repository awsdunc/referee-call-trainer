# Deploying Referee Call Trainer to AWS

The app is one static file, `site/index.html`, with no build step. There are two ways to put it on AWS.

## Option 1: AWS Amplify Hosting (no command line)

1. Open the AWS console and go to **AWS Amplify**.
2. Choose **Create new app**, then **Deploy without Git**.
3. Name the app `referee-call-trainer` and drag in `dist/referee-call-trainer-site.zip`.
4. Choose **Save and deploy**. Amplify prints the live URL, ending in `.amplifyapp.com`.

To update the site later, rebuild the zip (see below) and use **Deploy updates** on the same app.

## Option 2: S3 + CloudFront (scripted)

This creates a private S3 bucket served over HTTPS by CloudFront, using the CloudFormation template in this folder.

Requirements: the [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), signed in with `aws configure` or `aws sso login`. The account needs permission to use CloudFormation, S3 and CloudFront.

```sh
./deploy/aws/deploy.sh
```

The script creates or updates the `referee-call-trainer` stack, uploads `site/`, clears the CloudFront cache, and prints the URL (`https://xxxx.cloudfront.net`). The first run takes a few minutes while CloudFront sets up. Run it again after any change to `site/`.

You can override the defaults with environment variables: `STACK_NAME` (default `referee-call-trainer`) and `AWS_REGION` (default `us-east-1`).

To remove everything: `./deploy/aws/teardown.sh`

## Rebuilding the zip

```sh
rm -f dist/referee-call-trainer-site.zip
(cd site && zip -X ../dist/referee-call-trainer-site.zip index.html)
```

`index.html` must be at the top level of the zip, not inside a folder.
