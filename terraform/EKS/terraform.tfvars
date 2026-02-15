# AWS account config
region = "eu-central-1"

# General for all infrastructure
# This is the name prefix for all infra components
name = "sk"

vpc_id      = "vpc-0e9ce6f45b6762d99"
subnets_ids = ["subnet-067b46c896bbe7898", "subnet-043632b1e25028b4b", "subnet-08759cdae19a0a977"]

tags = {
  Environment = "dev"
  TfControl   = "true"
  Owner       = "svitlana.kizilpinar@gmail.com"
}

zone_name = "devops10.test-danit.com"
