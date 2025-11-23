variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.34"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "data-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "access_entries" {
  description = "EKS access entries configuration"
  type = map(object({
    # Access entry
    kubernetes_groups = optional(list(string))
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    tags              = optional(map(string), {})

    # Access policy association
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "producer-account"
  }
}

variable "enable_elasticache_redis" {
  description = "Enable ElastiCache Redis for Envoy Gateway rate limiting"
  type        = bool
  default     = true
}

variable "elasticache_redis_cluster_id" {
  description = "ElastiCache Redis cluster identifier"
  type        = string
  default     = "envoy-ratelimit-redis"
}



variable "ratelimit_auth_method" {
  description = "Authentication method for Envoy Rate Limit Service (irsa or pod_identity)"
  type        = string
  default     = "irsa"
  validation {
    condition     = contains(["irsa", "pod_identity"], var.ratelimit_auth_method)
    error_message = "ratelimit_auth_method must be either 'irsa' or 'pod_identity'."
  }
}



variable "elasticache_redis_serverless_max_storage" {
  description = "Maximum storage in GB for ElastiCache Serverless"
  type        = number
  default     = 10
}

variable "elasticache_redis_serverless_max_ecpu" {
  description = "Maximum ECPU per second for ElastiCache Serverless"
  type        = number
  default     = 30000
}

variable "elasticache_redis_serverless_min_ecpu" {
  description = "Minimum ECPU per second for ElastiCache Serverless"
  type        = number
  default     = 10000
}

variable "elasticache_redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "elasticache_redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "create_spot_service_linked_role" {
  description = "Whether to create the EC2 Spot service-linked role. Set to false if the role already exists in your AWS account (check with: aws iam get-role --role-name AWSServiceRoleForEC2Spot)"
  type        = bool
  default     = true
}

variable "elasticache_redis_username" {
  description = "Username for password-protected ElastiCache Redis user"
  type        = string
  default     = "envoy-ratelimit-password"
}

variable "elasticache_redis_default_access_string" {
  description = "Access string for the default (disabled) ElastiCache Redis user"
  type        = string
  default     = "off -@all"
}

variable "elasticache_redis_password_access_string" {
  description = "Access string for the password-protected ElastiCache Redis user"
  type        = string
  default     = "on ~* +@all"
}


variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "main-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.7.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.7.1.0/24", "10.7.2.0/24", "10.7.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.7.101.0/24", "10.7.102.0/24", "10.7.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT Gateway per availability zone (more expensive but higher availability)"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster (used for subnet tags)"
  type        = string
  default     = "my-eks-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "data-lab"
}

variable "enable_fck_nat" {
  description = "Use fck-nat instead of NAT Gateway (ultra cost-effective)"
  type        = bool
  default     = false
}

variable "fck_nat_instance_type" {
  description = "Instance type for fck-nat instance"
  type        = string
  default     = "t4g.nano"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "data-lab"
    Module      = "network"
  }
}

