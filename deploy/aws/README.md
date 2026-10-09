# Deploying Referee Call Trainer to AWS

The app is one static file, `site/index.html`, with no build step. Match mode has an online leaderboard, which needs a small backend: an API at `/api/scores` on the same address as the page.

There are two ways to put it on AWS. Only Option 2 includes the leaderboard. Without the backend, the page works as before and the leaderboard stays hidden.

## Option 1: AWS Amplify Hosting (no command line, no leaderboard)

1. Open the AWS console and go to **AWS Amplify**.
2. Choose **Create new app**, then **Deploy without Git**.
3. Name the app `referee-call-trainer` and drag in `dist/referee-call-trainer-site.zip`.
4. Choose **Save and deploy**. Amplify prints the live URL, ending in `.amplifyapp.com`.

To update the site later, rebuild the zip (see below) and use **Deploy updates** on the same app.

## Option 2: S3 + CloudFront with the leaderboard (scripted)

The CloudFormation template in this folder creates:

- a private S3 bucket for the page, served over HTTPS by CloudFront
- a DynamoDB table for scores (on-demand billing, with point-in-time recovery)
- a Lambda function behind an API Gateway HTTP API that reads and saves scores, limited to 10 requests a second
- a CloudFront rule that sends `/api/*` to that API, so the page and the API share one address

Requirements: the [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), signed in with `aws configure` or `aws sso login`. The account needs permission to use CloudFormation, S3, CloudFront, DynamoDB, Lambda, API Gateway and IAM, because the stack creates a role for the Lambda function.

```sh
./deploy/aws/deploy.sh
```

The script creates or updates the `referee-call-trainer` stack, uploads `site/`, clears the CloudFront cache, and prints the URL (`https://xxxx.cloudfront.net`). The first run takes a few minutes while CloudFront sets up. Run it again after any change to `site/`.

You can override the defaults with environment variables: `STACK_NAME` (default `referee-call-trainer`) and `AWS_REGION` (default `us-east-1`).

To remove everything, including all saved scores: `./deploy/aws/teardown.sh`

## How the leaderboard works

- At full time in Match mode, the player can enter a name (1 to 20 letters, numbers or spaces) and submit their match accuracy. The kick-off screen and the match report both show the top 10.
- The page remembers the last name used on that device.
- `GET /api/scores` returns the top 10. `POST /api/scores` with `{"name": "...", "pct": 0-100}` saves a score and returns the player's rank. Equal scores rank by who got there first.
- Scores are not verified. Anyone who finds the API can post any score, and names are not filtered for bad language. That's fine for a club or a group of friends. For a public board, add moderation, such as deleting entries in the DynamoDB console.

## Rebuilding the zip

```sh
rm -f dist/referee-call-trainer-site.zip
(cd site && zip -X ../dist/referee-call-trainer-site.zip index.html)
```

`index.html` must be at the top level of the zip, not inside a folder.
