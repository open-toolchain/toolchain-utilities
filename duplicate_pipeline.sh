#!/bin/bash
# uncomment to debug the script
# set -x
# This script does a duplication of a pipeline into an existing empty pipeline
# It requires cURL, jq (https://stedolan.github.io/jq/) and yq (https://github.com/mikefarah/yq) available
# You must be logged-in to the account, resource group and region that the toolchain/pipelines you want to duplicate from/to
# are hosted

BEARER_TOKEN=$(ibmcloud iam oauth-tokens --output JSON | jq -r '.iam_token')

REGION=$(ibmcloud target --output JSON | jq -r '.region.name')

OTC_API_SERVICE_INSTANCES_URL="https://devops-api.$REGION.devops.cloud.ibm.com/v1/service_instances"

PIPELINE_API_URL="https://devops-api.$REGION.devops.cloud.ibm.com/v1/pipeline"

if [ -z "$SOURCE_PIPELINE_ID" ]; then
  echo "Source pipeline not defined"
  exit 1
fi

if [ -z "$TARGET_PIPELINE_ID" ]; then
  # Retrieve source pipeline information to mint name/label/type
  curl -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json"  -o ${SOURCE_PIPELINE_ID}.json "$OTC_API_SERVICE_INSTANCES_URL/$SOURCE_PIPELINE_ID"
  TARGET_PIPELINE_NAME="$(cat $SOURCE_PIPELINE_ID.json | jq -r '.parameters.name')-copy"

  # Replace spaces with underscores
  TARGET_PIPELINE_NAME="${TARGET_PIPELINE_NAME// /_}"

  if [ -z "$TOOLCHAIN_ID" ]; then
    echo "Target toolchain not defined"
    exit 1
  fi
  # Create a new target pipeline
  curl -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json" \
    -X POST -o new_pipeline.json \
    --data-raw '{"service_id":"pipeline","container":{"guid":'$(ibmcloud target --output JSON | jq '.resource_group.guid')',"type":"resource_group_id"},"parameters":{"name": "'$TARGET_PIPELINE_NAME'"}}' "$OTC_API_SERVICE_INSTANCES_URL"
  TARGET_PIPELINE_ID=$(cat new_pipeline.json | jq -r '.instance_id')
  # Bind the new pipeline service instance to the toolchain
  curl -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json" -X PUT --data-raw '' "$OTC_API_SERVICE_INSTANCES_URL/$TARGET_PIPELINE_ID/toolchains/$TOOLCHAIN_ID"

  TARGET_PIPELINE_CREATED=true
fi
curl -H "Authorization: $BEARER_TOKEN" -H "Accept: application/x-yaml" -o "${SOURCE_PIPELINE_ID}.yaml" "$PIPELINE_API_URL/pipelines/$SOURCE_PIPELINE_ID"

echo "====================================================================================="
echo "YAML from source pipeline"
cat "${SOURCE_PIPELINE_ID}.yaml"
echo "====================================================================================="

# Find the token url for the git tile
curl -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json" -o "${SOURCE_PIPELINE_ID}_inputsources.json" "$PIPELINE_API_URL/pipelines/$SOURCE_PIPELINE_ID/inputsources"

# convert the yaml to json
yq r -j ${SOURCE_PIPELINE_ID}.yaml > ${SOURCE_PIPELINE_ID}.json

# Remove the hooks and (temporary workaround) the workers definition also
jq 'del(. | .hooks)' $SOURCE_PIPELINE_ID.json | jq 'del(.stages[] | .worker)' > "${TARGET_PIPELINE_ID}.json"

# Add the token url
jq -r '.stages[] | select(.inputs and .inputs[0].type=="git") | .inputs[0].url' $SOURCE_PIPELINE_ID.json |\
while IFS=$'\n\r' read -r input_gitrepo
do
  token_url=$(cat ${SOURCE_PIPELINE_ID}_inputsources.json | jq -r --arg git_repo "$input_gitrepo" '.[] | select( .repo_url==$git_repo ) | .token_url')
  echo "$input_gitrepo => $token_url"

  # Add a token field/line for input of type git and url being $git_repo
  cp -f $TARGET_PIPELINE_ID.json tmp-$TARGET_PIPELINE_ID.json

  jq -r --arg input_gitrepo "$input_gitrepo" --arg token_url "$token_url" '.stages[] | if ( .inputs[0].type=="git" and .inputs[0].url==$input_gitrepo) then  .inputs[0]=(.inputs[0] + { "token": $token_url}) else . end' tmp-$TARGET_PIPELINE_ID.json | jq -s '{"stages": .}' > ${TARGET_PIPELINE_ID}.json

done

# Add the pipeline properties in the target
cp -f $TARGET_PIPELINE_ID.json tmp-$TARGET_PIPELINE_ID.json
jq --slurpfile sourcecontent ./${SOURCE_PIPELINE_ID}.json '.stages | {"stages": ., "properties": $sourcecontent[0].properties }' ./tmp-${TARGET_PIPELINE_ID}.json > ${TARGET_PIPELINE_ID}.json

yq r $TARGET_PIPELINE_ID.json > $TARGET_PIPELINE_ID.yaml

# Include the yaml as rawcontent (ie needs to replace cr by \n and " by \" )
echo '{}' | jq --rawfile yaml $TARGET_PIPELINE_ID.yaml '{"config": {"format": "yaml","content": $yaml}}' > ${TARGET_PIPELINE_ID}_configuration.json

# HTTP PUT to target pipeline
curl -is -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json" -X PUT -d @${TARGET_PIPELINE_ID}_configuration.json $PIPELINE_API_URL/pipelines/$TARGET_PIPELINE_ID/configuration

# Check the configuration if it has been applied correctly
curl -H "Authorization: $BEARER_TOKEN" -H "Accept: application/json" $PIPELINE_API_URL/pipelines/$TARGET_PIPELINE_ID/configuration

# echoing the secured properties (pipeline and stage) that can not be valued there
echo "====================================================================================="
echo "The following pipeline secure properties needs to be updated with appropriate values:"
jq -r '.properties[] | select(.type=="secure") | .name' ${TARGET_PIPELINE_ID}.json

echo "The following stage secure properties needs to be updated with appropriate values:"
jq -r '.stages[] | . as $stage | .properties // [] | .[] | select(.type=="secure") | [$stage.name] + [.name] | join(" - ")' ${TARGET_PIPELINE_ID}.json
echo "====================================================================================="

# unset the TARGET_PIPELINE_ID that (may) have been set by this script
if [ "$TARGET_PIPELINE_CREATED" == "true" ]; then
  unset TARGET_PIPELINE_ID
fi
