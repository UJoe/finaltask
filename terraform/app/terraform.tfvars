# -----------------------------------------------------------------------------
# terraform.tfvars
#
# The values Terraform uses for the variables in variables.tf.
# This file IS committed to git: changing image_tag here in a pull request is
# how a new app version gets released (the pipeline then deploys it).
#
# List the image tags that exist in ECR with:
#   aws ecr describe-images --repository-name ugergo/finaltask --query 'imageDetails[].imageTags' --output text
# -----------------------------------------------------------------------------

image_tag = "v1.0"
