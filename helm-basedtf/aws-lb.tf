data "aws_iam_policy_document" "aws_lbc" {

  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "pods.eks.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {

  name = "${var.eks_name}-aws-load-balancer-controller"

  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

resource "aws_iam_policy" "aws_lbc" {

  name = "${var.eks_name}-aws-load-balancer-controller"

  policy = file("${path.module}/iam/AWSLoadBalancerController.json")
}
resource "aws_iam_role_policy_attachment" "aws_lbc" {

  role       = aws_iam_role.aws_lbc.name

  policy_arn = aws_iam_policy.aws_lbc.arn
}
resource "aws_eks_pod_identity_association" "aws_lbc" {

  cluster_name = aws_eks_cluster.eks.name

  namespace = "kube-system"

  service_account = "aws-load-balancer-controller"

  role_arn = aws_iam_role.aws_lbc.arn
}
resource "helm_release" "aws_lbc" {

  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"

  chart = "aws-load-balancer-controller"

  version = "3.4.0"

  namespace = "kube-system"

  create_namespace = false

  values = [

    yamlencode({

      clusterName = aws_eks_cluster.eks.name

      region = var.region

      vpcId = aws_vpc.main.id

      replicaCount = 2

      serviceAccount = {

        create = true

        name = "aws-load-balancer-controller"

      }

      enableServiceMutatorWebhook = true

    })

  ]

  depends_on = [

    aws_eks_pod_identity_association.aws_lbc,

    helm_release.cluster_autoscaler

  ]
}