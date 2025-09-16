# Simple variables for EFK infrastructure

variable "cluster_name" {
  description = "Name of the Minikube cluster"
  type        = string
  default     = "efk-monitoring"
}

variable "nodes" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory allocation for Minikube (MB)"
  type        = string
  default     = "4096"
}

variable "cpus" {
  description = "CPU allocation for Minikube"
  type        = string
  default     = "2"
}