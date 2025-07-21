provider "aws" {
  region                      = var.region
  profile                     = "dummy"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
