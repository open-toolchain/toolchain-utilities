Delivery Pipeline Private Worker customized installation
================

Collection of scripts to customize Delivery Pipeline Private Worker installation to pull images (private worker, tekton and optionnaly pipeline-base-image) from a private registry:
- `provision_private_worker_images.sh` script is used to pull images referenced in the private worker installation, push them to the target private registry and update the YAML file to reference this private registry's location for image(s)
- `change_images_scope.sh` script is used when cusomized installation has to be performed for an IBM Cloud Private (ICP) target. It changes the scope of the images used in private worker workload execution to be executable in the context of the temporary working namespaces - See https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_images/change_scope.html
- `provision_pipeline_base_images.sh`script is used to facilitate IBM pipeline base images push to a target private registry. Such images can then be referenced in classic pipeline job(s) execution or tekton pipeline task

## Pre-requisites
- The scripts require that the following utilities are pre-installed on your PATH: ibmcloud, curl, docker 
