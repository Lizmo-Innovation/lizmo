variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = <<-EOT
    Deployment region. asia-southeast1 (Singapore) keeps latency near ~40ms for
    Philippine users, versus ~200ms from the US.

    Note: GCP's always-free e2-micro VM tier is US-only, so this region rules
    that out — the database lives outside GCP instead (see db_url_secret).
  EOT
  type        = string
  default     = "asia-southeast1"
}

variable "github_repository" {
  description = <<-EOT
    The repository allowed to deploy, as "owner/name".

    Workload Identity Federation is scoped to this exact value — without the
    condition, any GitHub repository in the world could mint tokens for this
    provider.
  EOT
  type        = string
  default     = "ariel823/lizmo"
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
  default     = "lizmo-api"
}

variable "image" {
  description = <<-EOT
    Container image for the API. Defaults to a placeholder so `apply` can create
    the service before any image is pushed; CI replaces it on deploy, and
    Terraform ignores subsequent changes to it.
  EOT
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "cpu" {
  description = "vCPU per Cloud Run instance."
  type        = string
  default     = "1"
}

variable "memory" {
  description = <<-EOT
    Memory per instance. Spring Boot needs headroom — 512Mi risks OOM during
    startup, so 1Gi is the practical floor.
  EOT
  type        = string
  default     = "1Gi"
}

variable "min_instances" {
  description = <<-EOT
    Zero keeps the service inside the free tier, at the cost of a cold start
    (10-20s for Spring Boot). Set to 1 once that latency matters more than the
    bill — it is the single biggest cost/UX tradeoff in this stack.
  EOT
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Upper bound on scale-out, which caps worst-case spend."
  type        = number
  default     = 3
}

variable "billing_snapshot_cron" {
  description = "Monthly platform billing snapshot (product spec §3)."
  type        = string
  default     = "0 1 1 * *"
}

variable "billing_enforcement_cron" {
  description = "Daily sweep for overdue cycles and the 7-day lockout."
  type        = string
  default     = "0 2 * * *"
}

variable "scheduler_timezone" {
  description = "Timezone for scheduled jobs. Billing dates are calendar-day concepts, so this must match how landlords read them."
  type        = string
  default     = "Asia/Manila"
}
