#!/bin/sh
# openwhisk action implemented as script that will start a pipeline run 
# https://github.com/apache/openwhisk/blob/master/docs/actions-docker.md#creating-native-actions

IBM_CLOUD_API_KEY=$(echo $1 | jq -r '.ibm_cloud_api_key  // empty')
RESOURCE_GROUP=$(echo $1 | jq -r '.resource_group  // empty')
REGION=$(echo $1 | jq -r '.region // empty')
TOOLCHAIN_ID=$(echo $1 | jq -r '.toolchain_id // empty')
PIPELINE_ID=$(echo $1 | jq -r '.pipeline_id // empty')
STAGE_ID=$(echo $1 | jq -r '.stage_id // empty')

# Use the provided IBM Cloud Api Key or default to __OW_IAM_NAMESPACE_API_KEY environment variable
# https://cloud.ibm.com/docs/openwhisk?topic=cloud-functions-namespaces#namespace-access
API_KEY=${IBM_CLOUD_API_KEY:-$__OW_IAM_NAMESPACE_API_KEY}

# Prevent CLI version update check
ibmcloud config --check-version=false

if ibmcloud login --apikey "$API_KEY" -g "$RESOURCE_GROUP" -r "$REGION"; then
  if [ -z "$STAGE_ID" ]; then
    MESSAGE="Run for pipeline $PIPELINE_ID invoked"
    echo "$MESSAGE"
    if ibmcloud dev pipeline-run "$PIPELINE_ID"; then
      jq -r -c --arg message "$MESSAGE" --arg resource_group "$RESOURCE_GROUP" \
        --arg region "$REGION" --arg toolchain_id "$TOOLCHAIN_ID" --arg pipeline_id "$PIPELINE_ID" \
        '{msg: $message, resource_group: $resource_group, region: $region, toolchain_id: $toolchain_id, pipeline_id: $pipeline_id}'
    else
      MESSAGE="Error in run invocation for pipeline $PIPELINE_ID"
      jq -r -c --arg message "$MESSAGE" '{error: $message}'
    fi
  else 
    MESSAGE="Run for stage $STAGE_ID in pipeline $PIPELINE_ID invoked"
    echo "$MESSAGE"
    if ibmcloud dev pipeline-run "$PIPELINE_ID" --stage-id "$STAGE_ID"; then
      jq -r -c --arg message "$MESSAGE" --arg resource_group "$RESOURCE_GROUP" \
        --arg region "$REGION" --arg toolchain_id "$TOOLCHAIN_ID" --arg pipeline_id "$PIPELINE_ID" --arg stage_id "$STAGE_ID" \
        '{msg: $message, resource_group: $resource_group, region: $region, toolchain_id: $toolchain_id, pipeline_id: $pipeline_id, stage_id: $stage_id}'
    else
      MESSAGE="Error in run invocation for stage $STAGE_ID in pipeline $PIPELINE_ID"
      jq -r -c --arg message "$MESSAGE" '{error: $message}'
    fi
  fi
else
  MESSAGE="Error while login to ibmcloud --apikey *** -g $RESOURCE_GROUP -r $REGION"
  jq -r -c --arg message "$MESSAGE" '{error: $message}'
fi
