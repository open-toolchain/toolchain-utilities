Delivery Pipeline Private Worker customized installation
================

Collection of scripts to customize Delivery Pipeline Private Worker installation to pull images (private worker, tekton and optionnaly pipeline-base-image) from a private internal registry such as the one provided by IBM Cloud Private:
- `provision_private_worker_images.sh` script is used to pull images referenced in the private worker installation, push them to the target private registry and update the YAML file to reference this private registry's location for image(s)
- `change_images_scope.sh` script is used when customized installation has to be performed for an IBM Cloud Private (ICP) target. It changes the scope of the images used in private worker workload execution to be executable in the context of the temporary working namespaces.
  
  See https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_images/change_scope.html
- `provision_pipeline_base_images.sh` script is used to facilitate IBM pipeline base images push to a target private registry. Such images can then be referenced in classic pipeline job(s) execution or tekton pipeline task

## Pre-requisites
- The scripts require that the following utilities are pre-installed on your PATH: `ibmcloud`, `curl`, `docker` (see https://cloud.ibm.com/docs/cli?topic=cloud-cli-install-ibmcloud-cli) and `yq` (https://github.com/mikefarah/yq)
- Ensure that the namespaces `tekton-releases` and `ibmcom` are created in the target image registry

## Procedure to install private worker with images pulled from a private registry

1) Configure your docker client to be connected to your target private image registry.

   To target your IBM Cloud Private image registry, follow https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_images/configuring_docker_cli.html
   
   __Note:__ To retrieve the certificates defined during/for the IBM Cloud Private installation, you can use the kubernetes secrets definition in the ICP - See https://www.ibm.com/support/knowledgecenter/SSBS6K_3.2.0/installing/create_cert.html
   Typically, the CRT could be obtained by decoding the K8S secret
   ```
   kubectl get secret -n kube-public ibmcloud-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode
   ```

   ~~To target IBM Cloud Container registry, use `ibmcloud cr login` - This setup is documented at https://cloud.ibm.com/docs/Registry?topic=registry-getting-started#gs_registry_images_pushing~~

2) Set the environment variables to configure:
   - the region by set `region` environment variable (default to `us-south`). This is the region that your private worker will pull workload from
   - the target registry by set `target_cr` environment variable (default to `mycluster168.icp:8500` - which is the default for the IBM Cloud Private image registry)
   - (optional) the prefix that will be used to as a prefix to tag images pulled from docker hub (typically the `ibmcom` namespace one). To configure this, set `dockerio_mapping_prefix` environment variable

3) Download or copy `provision_private_worker_images.sh` to your work folder and then execute it.

   __Note:__ Alternative is to download it while source it using a cURL invocation
   
   `source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/toolchain-utilities/master/private-worker-using-private-registry-image/provision_private_worker_images.sh")` 

4) Configure images availabilty

   For an IBM Cloud Private image registry target, change the scope of the newly pushed images. 
   Follow https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_images/change_scope.html

   __Note:__ This can be done using the script `change_images_scope.sh`

   ~~For an IBM Cloud Container Registry, ensure that the service accounts `tekton-pipelines-controller` and `private-worker-agent` in `tekton-pipelines` namespace have access to the image pull secrets to target the container registry:~~
   ~~- Follow https://cloud.ibm.com/docs/containers?topic=containers-images#copy_imagePullSecret to copy the secrets to tekton-pipelines namespace.~~
   ~~- Read https://cloud.ibm.com/docs/containers?topic=containers-images#store_imagePullSecret to understand the configuration required for service accounts to use the newly created image pull secrets.~~
   ~~- Update `updated-private-worker-install.yaml` to add an imagePullSecrets entry for each of the service accounts.~~
   ~~Typically, you will add an entry like:
   ~~  ```~~
   ~~  imagePullSecrets:~~
   ~~  - name: tekton-pipelines-us-icr-io~~
   ~~  ```~~

5) Locate the last line of the command output to install the customized private worker
   ```
   Run the following command "kubectl apply --filename updated-private-worker-install.yaml" to install the delivery pipeline private worker
   ```

## Procedure to push pipeline-base-image images to a private registry

1) Configure your docker client to be connected to your target private image registry.
   To target IBM Cloud Container registry, use `ibmcloud cr login`
   To target your IBM Cloud Private image registry, TBD

2) Set the environment variables to configure:
   - the target registry by set `target_cr` environment variable (default to `mycluster168.icp:8500` - which is the default for the IBM Cloud Private image registry)
   - (optional) the prefix that will be used to as a prefix to tag images pulled from docker hub (typically the `ibmcom` namespace one). To configure this, set `dockerio_mapping_prefix` environment variable

3) Download or copy `provision_pipeline_base_images.sh` to your work folder and then execute it.

   __Note:__ Alternative is to download it while source it using a cURL invocation

   `source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/toolchain-utilities/master/private-worker-using-private-registry-image/provision_pipeline_base_images.sh")`
