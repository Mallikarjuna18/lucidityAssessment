data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}
provider "helm" {
  kubernetes = {
    host = aws_eks_cluster.eks.endpoint

    cluster_ca_certificate = base64decode(
      aws_eks_cluster.eks.certificate_authority[0].data
    )

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--region",
        var.region,
        "--cluster-name",
        aws_eks_cluster.eks.name
      ]
    }
  }
}
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.13.1"
}