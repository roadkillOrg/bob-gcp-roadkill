variable "project" {
  description = "GCP Project ID"
  type        = string
}

variable "host_project" {
  description = "Host project for shared VPC"
  type        = string
}

variable "region" {
  description = "Default GCP Region"
  type        = string
  default     = "us-west1"
}

variable "ce_machine_type" {
  description = "Default machine type for compute instances"
  type        = string
  default     = "n1-standard-1"
}
