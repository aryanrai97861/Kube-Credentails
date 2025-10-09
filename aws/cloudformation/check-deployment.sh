#!/bin/bash
echo "=== ECS Deployment Status ==="
echo

echo "1. Service Status:"
aws ecs describe-services --cluster kube-credentials-cluster \
  --services kube-credentials-issuer kube-credentials-verifier kube-credentials-frontend \
  --query 'services[*].{Service:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' \
  --output table

echo
echo "2. Running Tasks:"
TASK_ARNS=$(aws ecs list-tasks --cluster kube-credentials-cluster --desired-status RUNNING --query 'taskArns' --output text)
if [ -n "$TASK_ARNS" ]; then
  aws ecs describe-tasks --cluster kube-credentials-cluster --tasks $TASK_ARNS \
    --query 'tasks[*].{Group:group,Status:lastStatus,Health:healthStatus}' --output table
else
  echo "No running tasks found"
fi

echo
echo "3. Load Balancer URL:"
LB_URL=$(aws cloudformation describe-stacks --stack-name kube-credentials-infrastructure \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text)
echo "URL: $LB_URL"
echo "Testing connection..."
curl -I $LB_URL 2>/dev/null | head -1 || echo "Connection failed"

echo
echo "4. Recent Service Events:"
aws ecs describe-services --cluster kube-credentials-cluster --services kube-credentials-frontend \
  --query 'services[0].events[0:3].{Time:createdAt,Message:message}' --output table

