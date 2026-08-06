resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.9-eksbuild.5"

  tags = {
    Name = "${var.env}-${var.eks_name}-pod-identity"
  }

  depends_on = [aws_eks_node_group.general]
}