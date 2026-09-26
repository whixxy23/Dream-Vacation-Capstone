# Remote state storage.
#
# Bootstrap once, manually, BEFORE running `terraform init` with this block
# uncommented (Terraform cannot create the state bucket it will store its
# own state in):
#
  # aws s3api create-bucket --bucket dream-vacations-tfstate-whizzy23 \
  #   --region us-east-1
  # aws s3api put-bucket-versioning --bucket dream-vacations-tfstate-whizzy23 \
  #   --versioning-configuration Status=Enabled
  # aws dynamodb create-table --table-name dream-vacations-tf-locks \
  #   --attribute-definitions AttributeName=LockID,AttributeType=S \
  #   --key-schema AttributeName=LockID,KeyType=HASH \
  #   --billing-mode PAY_PER_REQUEST --region us-east-1
#
# Then fill in the real bucket name below and run:
#   terraform init -migrate-state

terraform {
  backend "s3" {
    bucket         = "dream-vacations-tfstate-whizzy23"
    key            = "dream-vacations/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dream-vacations-tf-locks"
    encrypt        = true
  }
}
