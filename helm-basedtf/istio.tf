resource "helm_release" "istio_base" {

  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.28.0"

  namespace         = "istio-system"
  create_namespace  = true

  wait    = true
  timeout = 900
  atomic  = true
}
resource "helm_release" "istiod" {

  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.28.0"

  namespace = "istio-system"

  wait    = true
  timeout = 900
  atomic  = true

  depends_on = [
    helm_release.istio_base
  ]
}
resource "helm_release" "istio_gateway" {

  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.28.0"

  namespace = "istio-system"

  wait    = true
  timeout = 900
  atomic  = true

  values = [
    yamlencode({

      service = {

        type = "LoadBalancer"

        annotations = {

          "service.beta.kubernetes.io/aws-load-balancer-type"             = "external"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"           = "internet-facing"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"  = "ip"
        }
      }

    })
  ]

  depends_on = [
    helm_release.istiod
  ]
}