variable "jumpbox_count" {
  description = "The number of jump boxes that we're going to deploy"
  type        = number
  default     = 1
}
variable "network_type" {
  description = "An identifier to indicate what type of network this is"
  type        = string
}
variable "deployment_name" {
  description = "The unique name for this particular deployment"
  type        = string
}
variable "jumpbox_ssh_access" {
  description = "Which CIDRs should be allow to SSH into the jumpbox"
  type        = list(string)
}
variable "network_acl" {
  description = "Which CIDRs should be allowed to access the explorer and RPC"
  type        = list(string)
}
variable "http_rpc_port" {
  description = "The TCP port that will be used for http rpc"
  type        = number
}

variable "devnet_id" {
  type = string
}

variable "validator_primary_network_interface_ids" {
  type        = list(string)
}
variable "fullnode_primary_network_interface_ids" {
  type        = list(string)
}
variable "jumpbox_primary_network_interface_ids" {
  type        = list(string)
}