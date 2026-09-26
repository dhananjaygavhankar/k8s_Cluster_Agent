# variable "subnet_id{}
variable "rg_location" {}
variable "cluster_name" {}
variable "name_rg" {}
variable "dns_prefix" {}
variable "subnet_id" {
	description = "ID of the dedicated subnet for AKS nodes"
	type        = string
}
variable "vm2take" {}
variable "o_version" {}

variable "acr_name" {
	description = "Globally unique alphanumeric name for the Azure Container Registry"
	type        = string

	validation {
		condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
		error_message = "acr_name must contain 5 to 50 alphanumeric characters only."
	}
}