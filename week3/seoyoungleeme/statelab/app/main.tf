provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "seoyoungleeme-test-bucket-12345"
}