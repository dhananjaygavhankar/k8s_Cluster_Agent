variable "aks_vnet" {
  description = "Dedicated AKS virtual network name"
  type        = string
}

variable "subnet_name" {
  description = "Dedicated AKS node subnet name"
  type        = string
}

variable "name_rg" {
  description = "Azure resource group name"
  type        = string
}

variable "rg_location" {
  description = "Azure region for this deployment"
  type        = string
}

variable "vm2take" {
  description = "VM SKU for the AKS default node pool"
  type        = string
}

variable "o_version" {
  description = "Requested Kubernetes version"
  type        = string
}

variable "acr_name" {
  description = "Globally unique alphanumeric Azure Container Registry name"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "AKS DNS prefix"
  type        = string
}

variable "pod_name" {
  description = "Kubernetes Pod name"
  type        = string
}

variable "pod_namespace" {
  description = "Kubernetes namespace for the agent Pod"
  type        = string
  default     = "default"
}

variable "pod_container_name" {
  description = "Container name in the Pod spec"
  type        = string
}

variable "pod_image" {
  description = "Container image name and tag"
  type        = string
}

variable "ado_url" {
  description = "Azure DevOps organization URL used by the agent"
  type        = string
  default     = "https://dev.azure.com/dhananjaygavhankar/"
}

variable "ado_pool" {
  description = "Azure DevOps agent pool name"
  type        = string
  default     = "Default"
}

variable "ado_agent" {
  description = "Azure DevOps agent registration name"
  type        = string
  default     = "docker_agent"
}

variable "ado_pat" {
  description = "Azure DevOps PAT supplied securely outside tracked tfvars files"
  type        = string
  sensitive   = true
  default     = "KINDLY ADD YOUR PAT TOCKEN"
}

variable "docker_context_path" {
  description = "Docker build context path; empty selects the image directory beside this module"
  type        = string
}

variable "pod_labels" {
  description = "Labels assigned to the agent Pod"
  type        = map(string)
}

variable "pod_cpu_request" {
  description = "CPU request for the agent container"
  type        = string
}

variable "pod_memory_request" {
  description = "Memory request for the agent container"
  type        = string
}

variable "pod_cpu_limit" {
  description = "CPU limit for the agent container"
  type        = string
}

variable "pod_memory_limit" {
  description = "Memory limit for the agent container"
  type        = string
}
