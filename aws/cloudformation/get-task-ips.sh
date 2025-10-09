#!/bin/bash
echo "=== Task Public IP Addresses ==="

RUNNING_TASKS=$(aws ecs list-tasks --cluster kube-credentials-cluster --desired-status RUNNING --query 'taskArns[]' --output text)

if [ -z "$RUNNING_TASKS" ]; then
  echo "No running tasks found"
  exit 0
fi

for task_arn in $RUNNING_TASKS; do
  task_id=$(echo $task_arn | rev | cut -d'/' -f1 | rev)
  
  # Get task details
  TASK_INFO=$(aws ecs describe-tasks --cluster kube-credentials-cluster --tasks $task_id \
    --query 'tasks[0].{Group:group,NetworkInterface:attachments[0].details[?name==`networkInterfaceId`].value | [0]}')
  
  SERVICE=$(echo $TASK_INFO | jq -r '.Group' | sed 's/service://')
  ENI=$(echo $TASK_INFO | jq -r '.NetworkInterface')
  
  if [ "$ENI" != "null" ]; then
    PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI \
      --query 'NetworkInterfaces[0].Association.PublicIp' --output text 2>/dev/null)
    
    if [ "$PUBLIC_IP" != "None" ] && [ -n "$PUBLIC_IP" ]; then
      echo "$SERVICE: http://$PUBLIC_IP (Task: $task_id)"
      case $SERVICE in
        *issuer*) echo "  -> Issuer API: http://$PUBLIC_IP:3001" ;;
        *verifier*) echo "  -> Verifier API: http://$PUBLIC_IP:4002" ;;
        *frontend*) echo "  -> Frontend: http://$PUBLIC_IP:80" ;;
      esac
    else
      echo "$SERVICE: No public IP (Task: $task_id)"
    fi
  fi
done
