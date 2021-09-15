Cloud Function Action and Time Trigger execution for _Classic_ Delivery Pipeline
================

Create Docker action container using IBM Cloud Functions/OpenWhisk to start a Delivery Pipeline run.

## Setup

1) Build and push the docker image containing the `pipeline-run.sh` script as `action/exec`

   Reminder: IBM Cloud Function can only use image from public registries - https://cloud.ibm.com/docs/openwhisk?topic=openwhisk-runtimes#openwhisk_ref_docker
   ```
   docker build -t cdjumpstart/pipeline-run-docker:1.0.0 -t cdjumpstart/pipeline-run-docker:latest .
   docker push cdjumpstart/pipeline-run-docker:1.0.0
   docker push cdjumpstart/pipeline-run-docker:latest
   ```
   Note: you can reuse the image provided at https://hub.docker.com/repository/docker/cdjumpstart/pipeline-run-docker

2) Create the cloud function namespace and set the CLI context to it
   ```
   ibmcloud fn namespace create pipeline-trigger-ns
   ibmcloud fn property set --namespace pipeline-trigger-ns
   ```

3) Create IBM Cloud docker action
   ```
   ibmcloud fn action create pipeline-run --docker cdjumpstart/pipeline-run-docker:1.0.0
   ```

4) Configure the action with the default toolchain context and pipeline to execute as function arguments.

   The arguments to provide are:
   - the region (as `region` argument)
   - the resource group (as `resource_group` argument)
   - the toolchain id (as `toolchain_id` argument)
   - the pipeline id (as `pipeline_id` argument)
   - (optional) the stage id (as `stage_id` argument) if the goal is to run a specific stage of the pipeline

   Notes: 
   - You can use the ibmcloud dev plugin to find easily the IDs.
   - Those arguments will be the default one for the function.
   ```
   ibmcloud fn action update pipeline-run \
     --param region us-south \
     --param resource_group default \
     --param toolchain_id 93918ab6-df3b-40e8-bbe7-d36a7aaadb1b \
     --param pipeline_id 1c14d6f5-32d9-4e59-9d7c-5713e6fbd6d6
   ```
5) Configure the authentication

   As described in https://cloud.ibm.com/docs/openwhisk?topic=openwhisk-namespaces#targeting-namespaces, giving Resource group and Toolchain access to IBM Cloud function service ID corresponding to the used namespace for IBM Cloud function provide a mechanism to set the apikey (`__OW_IAM_NAMESPACE_API_KEY`) used for `ibmcloud login` in the `pipeline-run.sh` script.

   Use the IAM UI to add access to the resource group(s) and the toolchain(s) that will be launched by the IBM Cloud Function action.
   
   __Notes__:
   - The `Editor` role must be given to the service id for the target Toolchain(s) in order to be able to run the pipeline(s).
   - If only `Operator` role is given, then to be able to run a pipeline, the stage started when running the pipeline needs to be configured in the input section to allow this stage to be run manually by all toolchain members. By default only toolchain members with write privileges can manually run a stage. When checked all toolchain members are granted this privilege too.


   __Alternative__: Define an `ibm_cloud_api_key` argument to the action with an arbitrary api key allowing to access the given pipeline
   ```
   ibmcloud fn action update pipeline-run \
     --param region us-south \
     --param resource_group default \
     --param toolchain_id 93918ab6-df3b-40e8-bbe7-d36a7aaadb1b \
     --param pipeline_id 1c14d6f5-32d9-4e59-9d7c-5713e6fbd6d6 \
     --param ibm_cloud_api_key <api key>
   ```
## Configure IBM Cloud Function trigger
With the pipeline-run function defined, you can now define a time trigger to start it.
See https://cloud.ibm.com/docs/openwhisk?topic=openwhisk-triggers

In the remaining section, we will define a trigger that will start a run of the configured pipeline every 2 minutes
1) Define the time trigger
    ```
    ibmcloud fn trigger create pipeline-run-every-2-minutes \
    --feed /whisk.system/alarms/interval \
    --param minutes 2
    ```
Note: if using Git bash on Windows, use this command to define the trigger:
    ```
    ibmcloud fn trigger create pipeline-run-every-2-minutes \
    --feed '//whisk.system\alarms\interval' \
    --param minutes 2
    ```
2) Create the rule that associate the trigger to the function
   ```
   ibmcloud fn rule create pipeline-run-rule pipeline-run-every-2-minutes pipeline-run
   ```
3) Optionnaly, you can monitor the activity by polling for the activation logs
   ```
   ibmcloud fn activation poll
   ```
  
