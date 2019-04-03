env_name           = "cp"
region             = "us-west-1"
availability_zones = ["us-west-1b", "us-west-1c"]
ops_manager_ami    = "ami-01b9c5d4ca3b79616"
rds_instance_count = 0
dns_suffix         = "aws.63r53rk54v0r.com"
vpc_cidr           = "10.0.0.0/16"
use_route53        = true

tags = {
    created_by = "aneumann"
}