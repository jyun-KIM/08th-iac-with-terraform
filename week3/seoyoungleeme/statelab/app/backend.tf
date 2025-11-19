terraform {
  backend "s3" {
    bucket         = "terraform-state-rudalsss-wave-01"
    key            = "app/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}