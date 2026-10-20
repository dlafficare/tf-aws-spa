variable "service_name" {
  description = "The name of the service. Used for S3 bucket naming. Must be globally unique, 3-63 lowercase alphanumeric characters and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.service_name))
    error_message = "Service name must be 3-63 characters, lowercase alphanumeric and hyphens only, cannot start or end with a hyphen."
  }
}

variable "performance_profile" {
  description = "The performance tier selected by the developer (sandbox, development, production). CDN caching and edge locations are automatically configured based on this profile."
  type        = string

  validation {
    condition     = contains(["sandbox", "development", "production"], var.performance_profile)
    error_message = "Performance profile must be one of: sandbox, development, production."
  }
}

variable "index_html" {
  description = "Inline HTML page published as index.html. When set, deployed_service and artifacts_bucket are ignored."
  type        = string
  default     = ""
}

variable "deployed_service" {
  description = "Name of the microservice whose build is published. Must match the microservice name in the Console: its pipeline uploads the static files under <name>/latest/ in the artifacts bucket. Used when index_html is empty."
  type        = string
  default     = ""
}

variable "artifacts_bucket" {
  description = "The S3 bucket where microservice pipelines upload their builds. Used when index_html is empty."
  type        = string
  default     = ""
}

variable "runtime_config" {
  description = "Values published as /config.json and read by the SPA at startup, as a JSON object (e.g. {\"apiUrl\": \"ref:api.api_url\"})."
  type        = any
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags to apply, as a JSON object (e.g. {\"team\": \"backend\"})."
  type        = any
  default     = {}
}
