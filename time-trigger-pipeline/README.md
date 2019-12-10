Cloud Function Action for Delivery Pipeline run
================

Create Docker action container using IBM Cloud Functions/OpenWhisk to start a Delivery Pipeline run.

### Setup

1) Build and push the docker image containing the `pipeline-run.sh` script as `action/exec`

   Reminder: IBM Cloud Function can only use image from public registries - https://cloud.ibm.com/docs/openwhisk?topic=cloud-functions-prep#prep_docker
   ```
   docker build -t jauninb/pipeline-run-docker:1.0 .
   docker push jauninb/pipeline-run-docker:1.0
   ```
   Note: you can reuse the image provided at https://hub.docker.com/repository/docker/jauninb/pipeline-run-docker

2) Create the cloud function namespace and set the CLI context to it
   ```
   ibmcloud fn namespace create pipeline-trigger-ns
   ibmcloud fn property set --namespace pipeline-trigger-ns
   ```

3) Create IBM Cloud docker action
   ```
   ibmcloud fn action create pipeline-run --docker jauninb/pipeline-run-docker:1.0
   ```

4) Configure the action with the default toolchain context and pipeline to execute as function arguments.

   The arguments to provide are:
   - the region (as `region` argument)
   - the resource group (as `resource_group` argument)
   - the toolchain id (as `toolchain_id` argument)
   - the pipeline id (as `pipeline_id` argument)

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

   Define an `ibm_cloud_api_key` argument to the action with the api key allowing to access the given pipeline
   ```
   ibmcloud fn action update pipeline-run \
     --param region us-south \
     --param resource_group default \
     --param toolchain_id 93918ab6-df3b-40e8-bbe7-d36a7aaadb1b \
     --param pipeline_id 1c14d6f5-32d9-4e59-9d7c-5713e6fbd6d6 \
     --param ibm_cloud_api_key <api key>
   ```

   Alternative/Known issue:
   - As described in https://cloud.ibm.com/docs/openwhisk?topic=cloud-functions-namespaces#service-id-set-ui, giving Resource group and Toolchain access to IBM Cloud function service ID corresponding to the used namespace should be a way to provide a valid apikey to the underlying `ibmcloud login`.

     Unfortunately, there is a problem while using `ibmcloud dev pipeline-run` within this context

## Configure IBM Cloud Function trigger
With the pipeline-run function defined, you can now define a time trigger to start it.
See https://cloud.ibm.com/docs/openwhisk?topic=cloud-functions-pkg_alarms

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
  
