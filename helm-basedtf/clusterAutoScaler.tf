resource "aws_iam_role" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "cluster_autoscaler" {

  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",

          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",

          "eks:DescribeNodegroup"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled" = "true"

            "aws:ResourceTag/k8s.io/cluster-autoscaler/${aws_eks_cluster.eks.name}" = "owned"
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {

  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {

  cluster_name = aws_eks_cluster.eks.name

  namespace = "kube-system"

  service_account = "cluster-autoscaler"

  role_arn = aws_iam_role.cluster_autoscaler.arn
}
resource "helm_release" "cluster_autoscaler" {

  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"

  # Compatible with Kubernetes 1.35
  version          = "9.58.0"

  namespace        = "kube-system"
  create_namespace = false

  values = [

    yamlencode({

      replicaCount = 1

      priorityClassName = "system-cluster-critical"

      awsRegion = var.region

      autoDiscovery = {
        clusterName = aws_eks_cluster.eks.name
      }

      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
        }
      }

      extraArgs = {

        balance-similar-node-groups = "true"

        skip-nodes-with-system-pods = "false"

        expander = "least-waste"
      }

      serviceMonitor = {
        enabled = false
      }

    })

  ]

  depends_on = [

    helm_release.metrics_server,

    aws_eks_pod_identity_association.cluster_autoscaler

  ]
}