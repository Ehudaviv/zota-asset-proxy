# Serverless Asset Proxy

Hey there! This is a secure, serverless asset proxy I built as a technical challenge. It’s designed to fetch private files from S3 and serve them through a global CDN using a Lambda function as the middleman.

## The Architecture
The flow is pretty straightforward but highly secure:
**Client** -> **CloudFront** -> **Lambda Function URL** -> **S3 (Private)**

- **S3:** Acts as the private vault. Public access is fully blocked.
- **Lambda:** A custom Go handler (compiled for `arm64`) that pulls the data.
- **CloudFront:** The global entry point. It uses Origin Access Control (OAC) to sign requests, ensuring that no one can bypass the CDN and hit the Lambda directly.

## Why I Built It This Way (Design Notes)
While building this, I focused on a few "SecOps-first" principles:

### 1. Modern Security (No More API Keys)
I used **OIDC (OpenID Connect)** for the GitHub Actions authentication. This means there are zero long-lived AWS credentials stored in GitHub Secrets. Instead, GitHub gets a short-lived, temporary token for every deployment. It’s much safer and follows the principle of least privilege.

### 2. The "Dual-Auth" Lambda Trick
One of the more interesting challenges was securing the Lambda Function URL. To get CloudFront OAC working correctly with a Function URL, the Lambda policy needs to explicitly allow both `lambda:InvokeFunctionUrl` and `lambda:InvokeFunction`. It's a small detail that makes a huge difference in preventing `403 Forbidden` errors.

### 3. Bulletproof CI/CD
The pipeline is split into two logical stages:
- **Build:** It builds a Docker image and tags it with the Git commit SHA. This ensures every deployment is **immutable**—you always know exactly what code is running.
- **Deploy:** This stage is automatically triggered by a successful build. It updates the CloudFormation stack and then **invalidates the CloudFront cache**. I added that last step because CloudFront loves to cache error responses, and this ensures you see your changes immediately.

## Getting Started
The infrastructure is defined entirely in `infrastructure/template.yaml`. 

To deploy a new version, just push to the `main` branch. The GitHub Action takes care of the container build, the ECR push, and the CloudFormation update.

## Quick Stats
- **Runtime:** Go 1.22 on Amazon Linux 2023 (AL2023)
- **Architecture:** ARM64 (for better cost-performance)
- **Deployment:** Fully automated via GitHub Actions