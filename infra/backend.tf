terraform {
  backend "s3" {
    bucket       = "videogarage-tfstate"
    key          = "videogarage/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
