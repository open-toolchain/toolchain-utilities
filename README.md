# Collection of Open Toolchain utilities

## Template extraction for an existing toolchain
The toolchain-to-template script takes a Toolchain URL and will generate an OTC Template in the current folder that when run creates a clone of you original toolchain.
See https://github.com/open-toolchain/toolchain-to-template

## Classic Pipeline Duplication
The [`duplicate_pipeline.sh`](duplicate_pipeline.sh) script allows to duplicate an existing pipeline _classic_ flavor in the toolchain. See the documentation of the script is [here](duplicate_pipeline_README.md)

## (Time) Trigger for Delivery Pipeline
The [README _Cloud Function Action for Delivery Pipeline_](time-trigger-pipeline/README.md) describes how to run a delivery pipeline on timely manner using IBM Cloud functions, alarms and rule.
See time-trigger-pipeline subdirectory.