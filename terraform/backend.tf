###############################################################################
# Remote state backend (S3, native locking via use_lockfile).
#
# The bucket below must already exist — create it with the bootstrap/ stack
# first, then update the bucket name here if you changed the default.
###############################################################################

terraform {
  backend "s3" {
    bucket       = "bedrock-tfstate-alt-soe-025-4827"
    key          = "project-bedrock/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
