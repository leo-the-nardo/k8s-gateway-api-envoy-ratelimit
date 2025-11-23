# EKS Cluster using terraform-aws-modules/eks/aws
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.3.1"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
  enable_cluster_creator_admin_permissions = true
  endpoint_private_access                  = true
  endpoint_public_access                   = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = merge(var.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  })

  access_entries = var.access_entries

  tags = merge(var.tags, {
    Terraform   = "true"
    Environment = var.environment
  })
}

# Tag subnets for Karpenter discovery
resource "aws_ec2_tag" "karpenter_subnet_tags" {
  for_each    = toset(module.vpc.private_subnets)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

locals {
  namespace = "karpenter"
}

################################################################################
# EC2 Spot Service-Linked Role
################################################################################
# Create the service-linked role for EC2 Spot Instances
# This is required for Karpenter to launch spot instances
# Note: Neither the Karpenter nor EKS modules create this - it's account-level
resource "aws_iam_service_linked_role" "spot" {
  count            = var.create_spot_service_linked_role ? 1 : 0
  aws_service_name = "spot.amazonaws.com"
  description      = "Service-linked role for EC2 Spot Instances (required by Karpenter)"
}

################################################################################
# Controller & Node IAM roles, SQS Queue, Eventbridge Rules
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.3.2"

  cluster_name = module.eks.cluster_name
  # enable_v1_permissions = true
  namespace = local.namespace

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.cluster_name
  create_pod_identity_association = true

  tags = var.tags

}

################################################################################
# Helm charts
################################################################################
# Data source for ECR public authorization token (required for Karpenter Helm chart)
resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = local.namespace
  create_namespace = true
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.2"
  wait             = false

  depends_on = [aws_ec2_tag.karpenter_subnet_tags]

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    webhook:
      enabled: false
    EOT
  ]

}

################################################################################
# Metrics Server Patch
################################################################################
# Patch metrics-server deployment to add --kubelet-insecure-tls flag
# This fixes the "Metrics API not available" error
resource "null_resource" "metrics_server_patch" {
  depends_on = [aws_eks_addon.metrics_server]

  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system
      kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
        {
          "op": "add",
          "path": "/spec/template/spec/containers/0/args/-",
          "value": "--kubelet-insecure-tls"
        }
      ]'
      kubectl rollout restart deployment/metrics-server -n kube-system
    EOT
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    tolerations = [
      {
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NoSchedule"
      }
    ]
  })
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    tolerations = [
      {
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NoSchedule"
      }
    ]
  })
}

module "eks_elb_controller" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.22"

  cluster_name                        = module.eks.cluster_name
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_version                     = module.eks.cluster_version
  oidc_provider_arn                   = module.eks.oidc_provider_arn
  enable_aws_load_balancer_controller = true


  aws_load_balancer_controller = {
    name          = "aws-load-balancer-controller"
    chart         = "aws-load-balancer-controller"
    chart_version = "1.14.0"
    namespace     = "kube-system"
    set = [
      {
        name  = "clusterName"
        value = module.eks.cluster_name
      },
      {
        name  = "region"
        value = var.aws_region
      },
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      }
    ]
    values = [
      <<-EOT
      webhook:
        enable: false
      tolerations:
        - key: "karpenter.sh/controller"
          operator: "Exists"
          effect: "NoSchedule"
      EOT
    ]
  }

  tags = var.tags
}
