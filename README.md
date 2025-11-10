# sample-python-app — AWS Fargate Automated Deployment (Terraform + GitHub Actions)

This repository demonstrates a fully automated pipeline that:

- Builds and containerizes `sample-python-app`
- Pushes images to Amazon ECR
- Provisions AWS infrastructure via Terraform (VPC, ALB, ECS Fargate, ECR, CloudWatch)
- Deploys the service in private subnets behind an internet-facing ALB
- Performs rolling updates when new commits are pushed to `main`

## Structure

- `Dockerfile` — containerizes the app, listens on configurable port (`5000` by default).
- `infra/` — Terraform configuration to create VPC, subnets, NAT, ALB, ECR, ECS, CloudWatch, IAM.
- `.github/workflows/deploy.yml` — GitHub Actions pipeline:
  1. Build Docker image.
  2. Push to ECR with tag = commit SHA.
  3. Run `terraform apply` with `image_uri` variable set to the new image -> triggers ECS rolling update.

## Prerequisites

1. Fork this repository.
2. Create GitHub repository secrets:
   - `AWS_ACCESS_KEY_ID` — IAM user with sufficient privileges (ECR, ECS, EC2 networking, IAM, CloudWatch, ELB, VPC)
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g., `us-east-1`)
   - `ECR_REPO_NAME` (e.g., `sample-python-app`)
3. Ensure `requirements.txt` includes `gunicorn` (or adapt Dockerfile command).

## How it works

- Terraform creates:
  - VPC with 2 public + 2 private subnets (across 2 AZs).
  - Internet Gateway and NAT Gateway(s).
  - ALB in public subnets (internet-facing), listener on port 80.
  - ECR repository.
  - ECS cluster and Fargate service in private subnets with `assign_public_ip = false`.
  - Security groups configured so ALB (SG) is public and ECS tasks only accept traffic from ALB SG on the app port.
  - CloudWatch Log Group for container logs.

- GitHub Actions:
  - On push to `main`, build and push Docker image and call `terraform apply` with `-var image_uri=<account>.dkr.ecr...:<sha>`.
  - Terraform updates the ECS task definition `image` field and ECS will perform a rolling deployment with the specified `minimum_healthy_percent` / `maximum_percent` settings.

## Use / Run

1. Ensure your fork's `main` branch has these files.
2. Set the GitHub secrets (see above).
3. Push a commit to `main`.
4. Watch Actions tab — the workflow builds the image, pushes to ECR, and applies Terraform.
   - Terraform will create infra on first run.
   - Subsequent pushes will push a new image tag and `terraform apply` will update ECS to the new image (rolling update).

## Important notes / assumptions

- Terraform uses the local backend in this demo (state stored by the runner during apply). For production use, configure an S3 backend (and create the bucket and DynamoDB lock table) — this can be bootstrapped separately.
- The IAM user used in GitHub secrets needs privileges to create VPCs, subnets, NAT/EIP, ALB, ECR, ECS, IAM roles, CloudWatch logs.
- No secrets are hard-coded. All sensitive creds go in GitHub Secrets.
- App listens on `5000` by default; change `APP_PORT` in Dockerfile or workflow if needed.

## Evidence / Acceptance checklist

After running the pipeline you should gather the following evidence:

- **Successful GitHub Actions run**: screenshot of the Actions run showing steps succeeded.
- **ECS service deployment**: screenshot of ECS console showing service updated and tasks healthy, include task definition revision and events showing deployment/rolling update.
- **App reachable at ALB DNS**: open `http://<ALB_DNS>` and show app response. ALB DNS is output by Terraform (also printed by the workflow at the end).
- **Networking checks**:
  - Tasks have **no public IPs** (verify in ECS task network details).
  - ALB is internet-facing and in public subnets.
  - Security group rules: ALB allows `0.0.0.0/0:80`, service only allows from ALB SG on app port.

## Troubleshooting

- If `terraform apply` fails due to limits for EIPs/NAT, check your AWS account limits.
- For debugging container logs, view CloudWatch Logs (log group `/ecs/sample-python-app`).
- If ALB health checks fail, confirm container responds on `/` and port `5000`.

