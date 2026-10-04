terraform {
  required_version = ">= 1.4.0"
}

variable "revision" {
  type    = string
  default = "initial"
}

variable "fail_plan" {
  type    = bool
  default = false

  validation {
    condition     = !var.fail_plan
    error_message = "Intentional sandbox plan failure. Set fail_plan to false to recover."
  }
}

resource "terraform_data" "storage" {
  input = {
    project   = "storage"
    workspace = terraform.workspace
    revision  = var.revision
  }
}

output "sandbox" {
  value = terraform_data.storage.output
}
