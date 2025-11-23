# Development Environment Configuration

# AWS Configuration
aws_region = "us-east-1"

# EKS Configuration
cluster_name       = "dev-eks-cluster"
kubernetes_version = "1.34"


# ElastiCache Serverless Redis Configuration for Envoy Gateway Rate Limiting
enable_elasticache_redis                 = true
elasticache_redis_cluster_id             = "envoy-ratelimit-redis"
elasticache_redis_engine_version         = "7.1" # Serverless requires Redis 7.1+
elasticache_redis_port                   = 6379
elasticache_redis_serverless_max_storage = 10    # Maximum storage in GB
elasticache_redis_serverless_max_ecpu    = 30000 # Maximum ECPU per second
elasticache_redis_serverless_min_ecpu    = 10000 # Minimum ECPU per second

# EKS Access Entries
# Note: admin_user entry removed because enable_cluster_creator_admin_permissions = true
# already grants admin access to the Terraform identity (producer-admin user)
# If you need to grant access to additional users, add them here
access_entries = {
  github_actions = {
    principal_arn = "arn:aws:iam::068064050187:role/github-actions-terraform-dev"
    type          = "STANDARD"
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}

# Tags
tags = {
  Environment = "dev"
  Project     = "data-lab"
  Owner       = "data-team"
  CostCenter  = "engineering"
}
elasticache_redis_username               = "envoy-ratelimit-user"
elasticache_redis_password_access_string = "on ~* +@all"
elasticache_redis_default_access_string  = "off -@all"


# Network Configuration for Development Environment ------

# AWS Configuration
aws_region = "us-east-1"

# VPC Configuration
vpc_name = "dev-vpc"
vpc_cidr = "10.7.0.0/16"

# Cost Optimization: Reduce to 2 AZs instead of 3
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnet Configuration (updated for 2 AZs)
private_subnet_cidrs = ["10.7.1.0/24", "10.7.2.0/24"]
public_subnet_cidrs  = ["10.7.101.0/24", "10.7.102.0/24"]

# Gateway Configuration - Ultra Cost Optimized with fck-nat
enable_nat_gateway     = false # Disable NAT Gateway when using fck-nat
single_nat_gateway     = true  # Use single NAT Gateway (saves ~$45/month)
one_nat_gateway_per_az = false # Disable per-AZ NAT Gateways
enable_fck_nat         = true  # Use fck-nat for ultra cost savings (~$3/month)
fck_nat_instance_type  = "t4g.nano"
enable_vpn_gateway     = false
enable_flow_logs       = false # Disable flow logs for dev (saves ~$10-50/month)

# Environment
environment  = "dev"
project_name = "data-lab"

