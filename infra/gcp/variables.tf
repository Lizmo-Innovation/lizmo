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

    Compared verbatim against GitHub's OIDC assertion, including case. The
    default here was a personal account long after the repository moved to an
    organisation -- which fails as "unable to acquire impersonated
    credentials", a message that says nothing about the name being wrong.
  EOT
  type        = string
  default     = "Lizmo-Innovation/lizmo"
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

variable "supabase_project_ref" {
  description = <<-EOT
    The Supabase project's reference id -- the string in its dashboard URL, and
    under Project Settings → General as "Reference ID".

    No default on purpose. It appears in the storage endpoint and in the
    database host, and a project that is recreated gets a new one; a default
    left over from an old project is a value that looks right, plans clean, and
    points at something that no longer exists.
  EOT
  type        = string
}

variable "storage_region" {
  description = <<-EOT
    The region Supabase reports beside the S3 endpoint.

    Part of the SigV4 signature rather than a routing hint, so a plausible-
    looking wrong value produces a 403 that reads exactly like a bad key.

    Singapore, to match var.region: the API and its database in different
    regions pays the round trip on every query, and a single screen makes
    several.
  EOT
  type        = string
  default     = "ap-southeast-1"
}

variable "storage_bucket" {
  description = "Supabase Storage bucket for tenant documents and payment proofs. Must be private."
  type        = string
  default     = "lizmo-uploads"
}

variable "mail_host" {
  description = "SMTP host. Brevo's relay."
  type        = string
  default     = "smtp-relay.brevo.com"
}

variable "mail_port" {
  description = "SMTP port. 587 is STARTTLS, which is what the prod profile requires."
  type        = number
  default     = 587
}

variable "mail_username" {
  description = <<-EOT
    Brevo SMTP login. Brevo shows this on its SMTP & API page and it is not
    always the account's email address.

    Not a secret -- it is a username, and it appears in plan output either way.
    The SMTP key beside it is, and lives in Secret Manager.
  EOT
  type        = string
}

variable "mail_from" {
  description = <<-EOT
    What lands in the recipient's inbox. Must be an address verified in Brevo,
    or every message is rejected at submission.
  EOT
  type        = string
}

variable "admin_service_name" {
  description = "Cloud Run service name for the internal console."
  type        = string
  default     = "lizmo-admin"
}

variable "admin_image" {
  description = <<-EOT
    Container image for the console. A placeholder by default so `apply` can
    create the service before anything is built -- which is the point: the
    console's image has to be built with the API's URL compiled into it, and
    that URL does not exist until this apply has run.
  EOT
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
