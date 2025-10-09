#!/bin/bash
echo "=== Kube Credentials Service Access ==="
echo

# Get current running tasks
TASKS=$(aws ecs list-tasks --cluster kube-credentials-cluster --desired-status RUNNING --query 'taskArns[]' --output text)

if [ -z "$TASKS" ]; then
  echo "‚ùå No running tasks found"
  exit 1
fi

echo "‚úÖ Found running tasks. Getting access information..."
echo

for task_arn in $TASKS; do
  task_id=$(basename $task_arn)
  
  # Get task details
  task_info=$(aws ecs describe-tasks --cluster kube-credentials-cluster --tasks $task_id --query 'tasks[0]' --output json)
  
  service_name=$(echo $task_info | grep -o '"group":"[^"]*' | cut -d'"' -f4 | sed 's/service://')
  eni_id=$(echo $task_info | grep -o '"networkInterfaceId","value":"[^"]*' | cut -d'"' -f4)
  
  if [ -n "$eni_id" ]; then
    public_ip=$(aws ec2 describe-network-interfaces --network-interface-ids $eni_id --query 'NetworkInterfaces[0].Association.PublicIp' --output text 2>/dev/null)
    
    if [ "$public_ip" != "None" ] && [ -n "$public_ip" ]; then
      echo "Ì∫Ä $service_name:"
      echo "   Public IP: $public_ip"
      
      case $service_name in
        *issuer*)
          echo "   Issuer API: http://$public_ip:3001"
          echo "   Health Check: curl http://$public_ip:3001/health"
          ;;
        *verifier*)
          echo "   Verifier API: http://$public_ip:4002"
          echo "   Health Check: curl http://$public_ip:4002/health"
          ;;
        *frontend*)
          echo "   Frontend: http://$public_ip:80"
          echo "   Health Check: curl http://$public_ip:80"
          ;;
      esac
      echo
    else
      echo "‚ö†Ô∏è  $service_name: No public IP available"
      echo
    fi
  fi
done

echo "Ì¥ó Load Balancer URL (may not work until all services are healthy):"
echo "   http://kube-credentials-alb-904715878.us-east-1.elb.amazonaws.com"
echo

echo "Ì≥ä Service Status:"
aws ecs describe-services --cluster kube-credentials-cluster --services kube-credentials-issuer kube-credentials-verifier kube-credentials-frontend --query 'services[*].{Service:serviceName,Running:runningCount,Desired:desiredCount}' --output table
