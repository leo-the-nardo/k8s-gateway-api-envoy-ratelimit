# Security Group for ElastiCache Redis
resource "aws_security_group" "elasticache_redis" {
  count       = var.enable_elasticache_redis ? 1 : 0
  name_prefix = "${var.elasticache_redis_cluster_id}-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for ElastiCache Redis used by Envoy Gateway rate limiting"

  # Allow Redis traffic from EKS cluster security group (non-TLS port 6379)
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
    description     = "Redis access from EKS cluster security group"
  }

  # Allow Redis TLS traffic from EKS cluster security group (TLS port 6380)
  ingress {
    from_port       = 6380
    to_port         = 6380
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
    description     = "Redis TLS access from EKS cluster security group"
  }

  # Allow Redis traffic from EKS node security group (for Fargate pods - non-TLS)
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
    description     = "Redis access from EKS node/Fargate security group"
  }

  # Allow Redis TLS traffic from EKS node security group (for Fargate/Karpenter pods - TLS port 6380)
  ingress {
    from_port       = 6380
    to_port         = 6380
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
    description     = "Redis TLS access from EKS node/Karpenter security group"
  }


  # Allow Redis traffic from all private subnets (Fargate pods use these - non-TLS)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    description = "Redis access from private subnets (Fargate pods)"
  }

  # Allow Redis TLS traffic from all private subnets (Fargate pods - TLS port 6380)
  ingress {
    from_port   = 6380
    to_port     = 6380
    protocol    = "tcp"
    cidr_blocks = data.terraform_remote_state.network.outputs.private_subnet_cidrs
    description = "Redis TLS access from private subnets (Fargate pods)"
  }

  # Fallback: Allow Redis traffic from entire VPC CIDR (non-TLS)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Redis access from VPC CIDR (fallback)"
  }

  # Fallback: Allow Redis TLS traffic from entire VPC CIDR (TLS port 6380)
  ingress {
    from_port   = 6380
    to_port     = 6380
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr_block]
    description = "Redis TLS access from VPC CIDR (fallback)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.elasticache_redis_cluster_id}-sg"
  })
}

# Note: ElastiCache Serverless doesn't use subnet groups or parameter groups
# Subnets are specified directly in the serverless cache resource
# Parameter groups are managed automatically by AWS for serverless

# ElastiCache Serverless Redis Cache
# Serverless automatically scales based on demand - no fixed nodes
resource "aws_elasticache_serverless_cache" "redis" {
  count = var.enable_elasticache_redis ? 1 : 0

  engine = "redis"
  name   = var.elasticache_redis_cluster_id
  cache_usage_limits {
    data_storage {
      maximum = var.elasticache_redis_serverless_max_storage
      unit    = "GB"
    }
    ecpu_per_second {
      minimum = var.elasticache_redis_serverless_min_ecpu
      maximum = var.elasticache_redis_serverless_max_ecpu
    }
  }

  daily_snapshot_time      = "03:00"
  description              = "Serverless Redis for Envoy Gateway rate limiting"
  kms_key_id               = null # Use default AWS managed key
  major_engine_version     = "7"  # Serverless requires Redis 7.x
  security_group_ids       = [aws_security_group.elasticache_redis[0].id]
  snapshot_retention_limit = 7
  subnet_ids               = module.vpc.private_subnets
  user_group_id            = aws_elasticache_user_group.redis[0].user_group_id

  tags = merge(var.tags, {
    Name        = var.elasticache_redis_cluster_id
    Description = "Serverless Redis for Envoy Gateway rate limiting"
  })

  depends_on = [
    aws_security_group.elasticache_redis,
    module.eks
  ]
}


# ElastiCache Users and User Group
resource "aws_elasticache_user" "default" {
  count = var.enable_elasticache_redis ? 1 : 0

  user_id       = "${var.elasticache_redis_cluster_id}-default"
  user_name     = "default"
  access_string = var.elasticache_redis_default_access_string
  engine        = "redis"

  # AWS Docs say: "The default user must have a password or be set to no password."
  # We will use a dummy password and disable the user access.
  authentication_mode {
    type      = "password"
    passwords = ["${random_password.default_user_password[0].result}"]
  }

  tags = var.tags
}

resource "random_password" "default_user_password" {
  count   = var.enable_elasticache_redis ? 1 : 0
  length  = 32
  special = false
}

# Password-protected user for Envoy Rate Limit (since IAM is not supported by the envoy ratelimiter service)
resource "random_password" "ratelimit_password" {
  count   = var.enable_elasticache_redis ? 1 : 0
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_elasticache_user" "password_user" {
  count         = var.enable_elasticache_redis ? 1 : 0
  user_id       = var.elasticache_redis_username
  user_name     = var.elasticache_redis_username
  access_string = var.elasticache_redis_password_access_string
  engine        = "redis"

  authentication_mode {
    type      = "password"
    passwords = [random_password.ratelimit_password[0].result]
  }

  tags = var.tags
}

resource "aws_elasticache_user_group" "redis" {
  count = var.enable_elasticache_redis ? 1 : 0

  engine        = "redis"
  user_group_id = "${var.elasticache_redis_cluster_id}-group"
  user_ids = [
    aws_elasticache_user.default[0].user_id,
    aws_elasticache_user.password_user[0].user_id
  ]

  tags = var.tags
}

data "aws_caller_identity" "current" {}
resource "kubernetes_secret" "ratelimit_redis_creds" {
  metadata {
    name      = "ratelimit-redis-creds"
    namespace = "envoy-gateway-system"
  }

  data = {
    # Authentication for Envoy Rate Limit Service (username:password format)
    # Used with REDIS_AUTH environment variable
    REDIS_PASSWORD = "${aws_elasticache_user.password_user[0].user_name}:${random_password.ratelimit_password[0].result}"
    # Redis endpoint URL (without credentials)
    REDIS_URL = "${aws_elasticache_serverless_cache.redis[0].endpoint[0].address}:${aws_elasticache_serverless_cache.redis[0].endpoint[0].port}"
  }

  type = "Opaque"

  depends_on = [
    aws_elasticache_serverless_cache.redis,
    random_password.ratelimit_password
  ]
}
