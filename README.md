# Cloud-Native Hello World on AWS EKS

> A production-grade deployment of a Python Flask application on Amazon EKS, complete with autoscaling, service mesh, observability, and infrastructure-as-code.

---

## 📁 Repository Structure

```
.
├── app/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── helm-basedtf/
│   ├── aws-lb.tf
│   ├── clusterAutoScaler.tf
│   ├── istio.tf
│   ├── metricServer.tf
│   └── prometheus.tf
│
├── kubeconfigfile/
│   ├── helloWorld-helm/
│   ├── app.yml
│   ├── service.yml
│   ├── hpa.yml
│   └── istio-ingress.yml
│
├── iam/
│
├── main.tf
├── vpc.tf
├── subnet.tf
├── eks-cluster.tf
├── eks-nodes.tf
├── route-table.tf
├── nat.tf
└── variables.tf
```

---

## Prerequisites

### AWS Permissions (ability to create and manage)

| Service | Resources |
|---|---|
| Networking | VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables |
| Compute | EC2, Amazon EKS, Auto Scaling Groups |
| Load Balancing | Elastic Load Balancers (ALB/NLB) |
| Security | IAM Roles & Policies |

### Required Tools

| Tool | Purpose |
|---|---|
| `aws` CLI | AWS authentication and cluster config |
| `terraform` | Infrastructure provisioning |
| `kubectl` | Kubernetes cluster management |
| `helm` | Kubernetes application packaging |
| `docker` | Container image build and push |
| `git` | Source control |

---

## 🔧 Setup

### Clone the Repository

```bash
git clone https://github.com/Mallikarjuna18/lucidityAssessment.git
cd lucidityAssessment/app
```

> This is the basic Python Flask app — Hello World!

---

## 1. Image Generation

```bash
# Login to Docker Hub
docker login -u <USER-NAME>
# (enter password when prompted)

# Build the application image
docker build -t hello-world-app .

# Verify the image
docker images

# Run the container locally
docker run -d -p 80:8080 --name hello-world hello-world-app
# Verify: docker ps, check port 80, and confirm web access

# Tag the image
docker tag hello-world-app malli183/helloworld:v1.0

# Push to Docker Hub
docker push <USER-NAME>/helloworld:v1.0
# Verify in Docker registry
```

---

## 2. Infrastructure & Cluster Creation

```bash
cd ../
```

### Why is Terraform Split into Two Phases?

The Terraform files are intentionally split to avoid a race condition where the Helm provider attempts to install Kubernetes resources before the EKS control plane and worker nodes are fully accessible.

The Helm provider requires a healthy Kubernetes API server and active worker nodes before deploying charts. Provisioning infrastructure first makes the deployment deterministic and easier to troubleshoot.

#### Phase A — Core Infrastructure

- VPC
- Public Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- IAM Roles
- Amazon EKS Cluster
- Managed Node Groups

#### Phase B — Platform Add-ons

- Metrics Server
- AWS Load Balancer Controller
- Istio
- Prometheus & Grafana
- Cluster Autoscaler

---

### Phase A: Provision the Infrastructure

```bash
terraform init      # Initialise Terraform
terraform validate  # Validate the configuration
terraform plan      # Review the execution plan
terraform apply     # Create the infrastructure
```

>  **This may take 10–15 minutes.**

Once the EKS cluster is created, update your local kubeconfig:

```bash
aws eks update-kubeconfig --region <aws-region> --name <cluster-name>
```
```bash
kubectl get nodes
```
<img width="864" height="106" alt="Screenshot 2026-08-06 at 9 35 10 AM" src="https://github.com/user-attachments/assets/6549443d-fa31-4be3-ac40-67ea20581552" />

---

### Phase B: Install Kubernetes Add-ons via Helm

```bash
mv helm-basedtf/* .

terraform init      # Initialise Terraform
terraform validate  # Validate the configuration
terraform plan      # Review the execution plan
terraform apply     # Install add-ons
```

This step installs:

| Component | Purpose |
|---|---|
| **Metrics Server** | Provides CPU and Memory metrics required by HPA |
| **AWS Load Balancer Controller** | Creates AWS ALB/NLB from Kubernetes Services and Ingress |
| **Istio** | Service mesh for traffic management, security, and observability |
| **Prometheus** | Metrics collection and monitoring |
| **Cluster Autoscaler** | Automatically scales worker nodes based on pending pods |

---

### Cluster Autoscaler

The EKS Managed Node Group defines the scaling boundaries:

```
Minimum Nodes : 2
Desired Nodes : 2
Maximum Nodes : 5
```

> **Important:** These values only define the scaling boundaries. Amazon EKS does **not** automatically increase or decrease worker nodes when pods become unschedulable.

To enable automatic node scaling, a node provisioning component is required. This project uses **Cluster Autoscaler**, which:

- Monitors the Kubernetes scheduler for pending (unschedulable) pods
- Increases the desired capacity of the EKS Managed Node Group when additional nodes are needed
- Removes underutilised nodes when they are no longer required (subject to scale-down policies)

Without Cluster Autoscaler (or Karpenter), the node count remains fixed at the desired size even if the node group's maximum allows additional instances.

> **Note:** Cluster Autoscaler respects the minimum and maximum limits on the EKS Managed Node Group and scales only within those boundaries.

---

### Verify the Cluster

```bash
kubectl get ns
kubectl get pods -n kube-system
kubectl get pods -n monitoring
```
<img width="1260" height="530" alt="image" src="https://github.com/user-attachments/assets/6db11edf-217b-4d22-b397-6ae84239336e" />


Once healthy, the cluster is ready to deploy workloads, allow traffic, and serve production.

---

### Create and Label the Namespace

```bash
# Create namespace
kubectl create namespace lucidity

# Label for Istio sidecar injection
kubectl label namespace lucidity istio-injection=enabled

#verify
kubectl get ns
```

---

## 3. Deploy the Application using Helm

I have added what are the config files used for helm creation in kubeconfigfile folder.
We will be deploying a deployment, service, hpa and istio-ingress.

The Helm chart packages all Kubernetes resources required by the application, allowing it to be deployed, upgraded, and rolled back with a single command.

### Chart Structure

```
helloWorld-helm/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yml
    ├── service.yml
    ├── hpa.yml
    └── istio-ingress.yml
```

---

### Chart Components

#### `Chart.yaml`
Contains chart metadata: name, version, description, application version, and maintainer information.

#### `values.yaml`
Centralises all configurable parameters, allowing the same chart to be reused across environments without modifying templates.

Configures:
- Replica count
- Docker image
- Resource requests and limits
- Service configuration
- Horizontal Pod Autoscaler settings
- Istio Gateway configuration

#### Deployment
Creates application Pods. Configures container image, replica count, resource requests/limits, labels, selectors, and image pull policy.

#### Service
Exposes the application internally within the cluster using a ClusterIP Service — the stable endpoint that routes traffic to application Pods.

#### Horizontal Pod Autoscaler (HPA)
Automatically scales the number of Pods based on CPU utilisation. Minimum replicas, maximum replicas, and target CPU utilisation are all configurable via `values.yaml`.

#### Istio Gateway
Configures the Istio Ingress Gateway to receive external HTTP traffic on port 80 — the entry point into the service mesh.

#### Istio VirtualService
Defines how incoming requests are routed:

- Requests to `/hello`
- are rewritten to `/`
- and forwarded to the application's Kubernetes Service

This allows the application to be accessed at:

```
http://<LoadBalancer-DNS>/hello
```

#### Helper Templates (`_helpers.tpl`)
Contains reusable template functions for consistent resource naming across all manifests (application name, full resource name, common labels).

---

> The Helm chart makes the deployment portable, reusable, and easy to manage by packaging all required Kubernetes resources into a single deployable unit.

## Add the Helm Repository

```bash
helm repo add helloworld https://mallikarjuna18.github.io/helloWorldHelm
helm repo update
```

Verify that the chart is available:

```bash
helm search repo helloworld
```

Expected output:

```text
NAME                         CHART VERSION
helloworld/lucidity-test     0.1.x
```
## Install the Helm Chart

Create the application namespace (if it does not already exist):

```bash
kubectl create namespace lucidity
kubectl label namespace lucidity istio-injection=enabled
```

Install the application:

```bash
helm install my-app helloworld/lucidity-test \
  --namespace lucidity
```

Verify the Helm release:

```bash
helm list -n lucidity
```

Verify the deployed resources:

```bash
kubectl get all -n lucidity
```

## Upgrade the Application

If you publish a newer chart version, upgrade using:

```bash
helm upgrade my-app helloworld/lucidity-test -n lucidity
```
<img width="1177" height="206" alt="image" src="https://github.com/user-attachments/assets/35eaaf20-c1df-4bc2-8e77-483d27a6a814" />

---

### Validate the Deployment

```bash
kubectl get all -n lucidity
```
<img width="1503" height="478" alt="image" src="https://github.com/user-attachments/assets/3f60366f-2fe4-43b5-9dbf-3b0edcce9b0e" />

also can be verified by 
```bash
helm list - A
```

### Access the Application

```bash
# Get the Istio Ingress Gateway external IP
kubectl get svc -n istio-system
```

```
http://<EXTERNAL-IP>/app
```
<img width="1503" height="478" alt="image" src="https://github.com/user-attachments/assets/60411ff4-a4b6-400e-8d95-11ba15fb31f1" />

### Access Prometheus

```bash
kubectl get svc kube-prometheus-stack-prometheus -n monitoring
```

```
http://<External-IP>:9090/
```
<img width="1501" height="835" alt="Screenshot 2026-08-05 at 11 22 47 PM" src="https://github.com/user-attachments/assets/c23a99bf-17be-42ed-92a6-d00ac8bd9de4" />

---

## Application is Live!

> **Oh wait — is it scaling?** Let's check! 👇
 # 1. Testing Horizontal Pod Autoscaler (HPA)

To verify that the **Horizontal Pod Autoscaler (HPA)** is functioning correctly, I configured the target CPU utilization to **1%** in the Helm chart.

A continuous stream of requests was then generated using a **BusyBox** pod to create CPU load on the application.

As the CPU utilization exceeded the configured threshold, Kubernetes automatically increased the number of application replicas.

The following screenshot shows the HPA scaling the application pods:

<img width="1507" height="875" alt="HPA Scaling" src="https://github.com/user-attachments/assets/d9972ed8-194f-49a1-a7c1-f429af55a72a" />

You can also verify the HPA using:

```bash
kubectl get hpa -n lucidity
```

Watch the pods scale in real time:

```bash
kubectl get pods -n lucidity -w
<img width="1507" height="875" alt="Screenshot 2026-08-06 at 7 47 52 AM" src="https://github.com/user-attachments/assets/d9972ed8-194f-49a1-a7c1-f429af55a72a" />
You can verify that pods are scaling.
```
# 6. Testing Cluster Autoscaler

To verify the **Cluster Autoscaler**, I deployed a workload with CPU and memory requests that exceeded the available capacity of the existing worker nodes.

Since Kubernetes could not schedule the new pods, they entered the **Pending** state.

The Cluster Autoscaler detected these unschedulable pods and automatically increased the desired capacity of the Amazon EKS Managed Node Group by provisioning an additional EC2 worker node.

The screenshot below shows a new worker node joining the cluster after the workload was deployed:

<img width="1512" height="888" alt="Cluster Autoscaler" src="https://github.com/user-attachments/assets/8865fc13-86a4-49e8-8864-dc9994d50876" />

You can verify the newly created worker node using:

```bash
kubectl get nodes
```

Watch nodes being added in real time:

```bash
kubectl get nodes -w
```

Verify the pending pods:

```bash
kubectl get pods -A
```

Verify the Cluster Autoscaler logs:

```bash
kubectl logs -n kube-system deployment/cluster-autoscaler -f
```

Once the workload is removed and node utilization falls below the configured threshold, the Cluster Autoscaler will automatically scale the node group back down (subject to the configured scale-down delay).

This project demonstrates:

- Infrastructure as Code with Terraform
- Kubernetes application deployment
- Helm chart development
- Service Mesh with Istio
- Monitoring with Prometheus & Grafana
- Horizontal Pod Autoscaling
- Cluster Autoscaling
- AWS Load Balancer integration
- Production-ready EKS architecture





