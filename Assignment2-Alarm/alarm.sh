#!/bin/bash

# Before executing the script we need to configure the awscli with credentials like access-key secret-access-key and the region using a command
# "aws configure"
# Make script execuatble using "chmod u+x alarm.sh"
# Execute the script "./alarm.sh"


instance_id="i-0b81c286e2c042bd7"

aws cloudwatch put-metric-alarm \
  --alarm-name "CPUUsageAlarm" \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 5 \
  --metric-name "CPUUtilization" \
  --namespace "AWS/EC2" \
  --period 60 \
  --statistic "Average" \
  --threshold 80 \
  --alarm-description "Alert when CPU usage exceeds 80% for five consecutive minutes" \
  --dimensions "Name=InstanceId,Value=${instance_id}" \

