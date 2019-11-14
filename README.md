# Collection of Open Toolchain utilities

## Pipeline Duplication
The `duplicate_pipeline.sh` script allows to duplicate an existing pipeline _classic_ flavor in the toolchain.

### Setup
1) The `duplicate_pipeline.sh` script requires that the following utilities are pre-installed on your PATH: ibmcloud, curl, jq (https://stedolan.github.io/jq/), and yq (https://github.com/mikefarah/yq) 
2) Use ibmcloud CLI to login to the account where your toolchain resides and target the appropriate region and resource-group
3) Download and copy `duplicate_pipeline.sh` to your work folder.
  Note: Alternative is to download it while source it using a cURL invocation
  `source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/toolchain-utilities/master/duplicate_pipeline.sh")`

### Run the script
1) Identify the toolchain ID and the pipeline ID.
   You can use the ibmcloud dev plugin to find easily the IDs.
   ```
    $ ibmcloud dev toolchain-get helm-java-toolchain
    The toolchain-get feature is currently in Beta.
    Please provide your experience and feedback at:
    https://ibm-cloud-tech.slack.com/messages/developer-tools/

    Retrieving toolchain......

    ===============================================================================
    Name: helm-java-toolchain
    ID: 86431b6c-54bf-43d2-88d9-ae31460c11f6
    Resource Group: default
    URL:
    https://cloud.ibm.com/devops/toolchains/86431b6c-54bf-43d2-88d9-ae31460c11f6?env_id=ibm:yp:eu-de

    Created: 2019-10-23T12:23:22.083Z

    Toolchain Integrations:

    pipeline: pipeline
    ID: 50ed4b37-7b22-4fe6-b0f3-2de8a12e87a2
    https://cloud.ibm.com/devops/pipelines/50ed4b37-7b22-4fe6-b0f3-2de8a12e87a2?env_id=ibm:yp:eu-de

    hostedgit: java-app-20191023122210097
    https://eu-de.git.cloud.ibm.com/jaunin.b/java-app-20191023122210097

    ===============================================================================

   ```
2) set the TOOLCHAIN_ID and SOURCE_PIPELINE_ID environment variables to the appropriate values
   ```
   TOOLCHAIN_ID=86431b6c-54bf-43d2-88d9-ae31460c11f6
   SOURCE_PIPELINE_ID=50ed4b37-7b22-4fe6-b0f3-2de8a12e87a2
   ```

3) In a shell, run the following: `source ./duplicate_pipeline.sh` or `source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/toolchain-utilities/master/duplicate_pipeline.sh")`

The script will create a new pipeline with name being "<SOURCE PIPELINE NAME>-copy" in the toolchain.

The tail of the script execution logs indicates the pipeline secured properties or stage(s) secured properties that needs to be set manually in the new pipeline

### Known limitations
- Secured properties value are not copied/set in the duplicated pipeline
