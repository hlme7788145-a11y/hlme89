#!/bin/bash
set -e

AWS_REGION=us-east-1
AWS_ACCOUNT=778814589714
SECRET_NAME=hlme77881458
ECR_REPO=hlme89
ECR_IMAGE=${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# 1) Create secret (replace <SECRET_VALUE> with the actual secret value)
aws secretsmanager create-secret --name ${SECRET_NAME} --description "secret for hlme89" --secret-string '{"EXAMPLE_SECRET":"<SECRET_VALUE>"}' --region ${AWS_REGION}

# 2) Create IAM roles
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://trust-execution.json || true
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || true

aws iam create-role --role-name ecsTaskRole --assume-role-policy-document file://trust-task.json || true

# 3) Create and attach secret policy (local scope)
aws iam create-policy --policy-name hlme89-secrets-get --policy-document file://secret-policy.json || true
POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='hlme89-secrets-get'].Arn" --output text)
if [ -n "${POLICY_ARN}" ]; then
  aws iam attach-role-policy --role-name ecsTaskRole --policy-arn ${POLICY_ARN} || true
fi

# 4) Create ECR repo and push image
aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION} || true
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker build -t ${ECR_REPO}:latest .
docker tag ${ECR_REPO}:latest ${ECR_IMAGE}
docker push ${ECR_IMAGE}

# 5) Register task definition (ensure .aws/task-definition.json exists)
aws ecs register-task-definition --cli-input-json file://.aws/task-definition.json --region ${AWS_REGION}

# 6) Create cluster and service (replace SUBNETS and SECURITY_GROUP_ID)
CLUSTER_NAME=hlme89-cluster
SERVICE_NAME=hlme89-service
aws ecs create-cluster --cluster-name ${CLUSTER_NAME} --region ${AWS_REGION} || true

# Replace these with your VPC subnets and security group
SUBNETS="subnet-aaa,subnet-bbb"
SECURITY_GROUP_ID="sg-0123456789abcdef0"

aws ecs create-service \
  --cluster ${CLUSTER_NAME} \
  --service-name ${SERVICE_NAME} \
  --task-definition hlme89-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}" \
  --region ${AWS_REGION}
