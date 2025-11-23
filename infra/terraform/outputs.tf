output "private_subnet_ids" {
  description = "Private subnet IDs for NLB service"
  value       = module.vpc.private_subnets
}

# ElastiCache Redis outputs for Envoy Gateway rate limiting
output "elasticache_redis_endpoint" {
  description = "ElastiCache Redis endpoint address"
  value       = var.enable_elasticache_redis ? aws_elasticache_serverless_cache.redis[0].endpoint[0].address : null
}

output "elasticache_redis_port" {
  description = "ElastiCache Redis port"
  value       = var.enable_elasticache_redis ? aws_elasticache_serverless_cache.redis[0].endpoint[0].port : null
}

output "elasticache_redis_connection_url" {
  description = "ElastiCache Redis connection URL for Envoy Gateway"
  value       = var.enable_elasticache_redis ? "${aws_elasticache_serverless_cache.redis[0].endpoint[0].address}:${aws_elasticache_serverless_cache.redis[0].endpoint[0].port}" : null
}

output "elasticache_redis_cluster_id" {
  description = "ElastiCache Redis cache identifier"
  value       = var.enable_elasticache_redis ? aws_elasticache_serverless_cache.redis[0].name : null
}

# EKS Security Groups for verification
output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

# Karpenter outputs
output "karpenter_node_role_arn" {
  description = "ARN of the Karpenter node IAM role"
  value       = module.karpenter.node_iam_role_arn
}

output "karpenter_node_instance_profile_name" {
  description = "Name of the Karpenter node instance profile"
  value       = module.karpenter.node_iam_role_name != null ? "${module.karpenter.node_iam_role_name}" : null
}

output "karpenter_queue_name" {
  description = "Name of the Karpenter interruption queue"
  value       = module.karpenter.queue_name
}
