variable "project_id" {
  description = "ID проекта Selectel"
  type        = string
}

variable "location_id" {
  description = "ID локации для подсети"
  type        = string
}

variable "vlan_id" {
  description = "VLAN ID для приватной подсети"
  type        = string
}

variable "cidr" {
  description = "CIDR подсети (например, 10.10.14.0/24)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+$", var.cidr))
    error_message = "cidr должен быть в формате CIDR (например, 10.0.0.0/24)."
  }
}

variable "create" {
  description = "Создать подсеть (true) или найти существующую (false)"
  type        = bool
  default     = true
}

variable "timeouts" {
  description = "Таймауты для операций с подсетью"
  type = object({
    create = optional(string, "10m")
    delete = optional(string, "10m")
  })
  default = {}
}
