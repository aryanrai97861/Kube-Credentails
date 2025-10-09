#!/bin/bash
echo "=== Recent Application Logs ==="

for service in issuer verifier frontend; do
  echo
  echo "=== $service Service Logs ==="
  LOG_GROUP="/ecs/kube-credentials-$service"
  
  # Get the most recent log stream
  STREAM=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP" \
    --order-by LastEventTime --descending --max-items 1 \
    --query 'logStreams[0].logStreamName' --output text 2>/dev/null)
  
  if [ "$STREAM" != "None" ] && [ -n "$STREAM" ]; then
    echo "Latest log stream: $STREAM"
    echo "Recent logs:"
    aws logs get-log-events --log-group-name "$LOG_GROUP" \
      --log-stream-name "$STREAM" --limit 10 \
      --query 'events[*].[timestamp,message]' --output text 2>/dev/null | tail -5
  else
    echo "No logs found for $service service"
  fi
done
