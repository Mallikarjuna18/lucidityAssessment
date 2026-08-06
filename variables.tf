variable "env" {
  description = "evaluation"
  type        = string
  default = "evaluation"
}
variable "region" {
  description = "region"
  type        = string
  default = "us-east-1"
}
variable "eks_name" {
  description = "Cluster name"
  type        = string
  default = "eks-evaluation"
}
variable "eks_version" {
  description = "verison"
  type        = string
  default = "1.35"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}
variable "node_group_name" {
  description = "EKS Node Group Name"
  type        = string
  default     = "general"
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for worker nodes"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "max_unavailable" {
  description = "Maximum unavailable nodes during updates"
  type        = number
  default     = 1
}