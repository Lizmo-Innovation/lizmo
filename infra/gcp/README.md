# Lizmo — GCP infrastructure

Terraform for the production stack. Replaces the AWS CloudFormation design in
tech spec §6, which assumed ECS Fargate, RDS and an ALB.

## Shape

```
Phones ─────HTTPS──> Cloud Run: lizmo-api (asia-southeast1)
Console ────HTTPS──> Cloud Run: lizmo-admin           │
                                                      ├── Secret Manager   (db credentials, JWT key, SMTP key, storage keys)
                                                      ├── Supabase Postgres (Singapore, over the session pooler)
                                                      ├── Supabase Storage  (uploads, via signed S3 URLs)
                                                      └── Brevo             (SMTP)

Cloud Scheduler ──OIDC──> /internal/jobs/*   — created PAUSED, see below
```

## Why this differs from the tech spec

| Tech spec (AWS) | Here | Reason |
|---|---|---|
| ECS Fargate + ALB | Cloud Run | Scales to zero and terminates TLS itself; an external HTTPS load balancer is billable |
| RDS PostgreSQL | Supabase Postgres | Cloud SQL is **not** in GCP's always-free tier |
| S3 | Supabase Storage | S3-compatible, so the existing client and presigner work unchanged. A Cloud Storage bucket would have meant writing and proving a new client first |
| Secrets Manager | Secret Manager | Direct equivalent |
| Spring `@Scheduled` | Cloud Scheduler | With `min_instances = 0` an in-process scheduler never fires while asleep |

Everything sits in the always-free tier. The one real cost lever is
`min_instances`: at `0` you stay free and pay a 10–20s Spring Boot cold start on
the first request after idle; at `1` the service is always warm and always
billed.

**Both regions must match.** Supabase in Singapore and Cloud Run in Singapore
means ~1ms between the API and its database. Split them and every query pays the
round trip — and one screen makes several, so it reads as "the app is slow"
rather than as a configuration mistake.

---

## Before you start

- **gcloud CLI** installed and `gcloud auth application-default login` done.
- A **GCP project with billing enabled** — even free-tier resources refuse to
  create without it.
- A **Supabase project in Singapore** (`ap-southeast-1`).
- A **Brevo account** with a verified sender address.

### Supabase

1. **Storage → New bucket**, named `lizmo-uploads`, **private**. Signed URLs are
   the entire access model; a public bucket serves tenants' ID photographs to
   anyone holding the object path.
2. **Storage → Settings → S3 Connection** → enable it → **New access key**. The
   key ID and secret are shown once.
3. **Project Settings → Database → Connection string → Session pooler.** Host
   `aws-0-ap-southeast-1.pooler.supabase.com`, port **5432**, user
   `postgres.<project-ref>`.

   Not the direct connection: that host is IPv6-only and Cloud Run cannot reach
   it at all. Not port 6543 either — that is transaction mode, and Flyway takes
   a session-level advisory lock that transaction pooling does not support, so
   migrations hang or fail on the first deploy.

### Brevo

SMTP & API → the **login** (not always your account's email address) and an
**SMTP key**. The from-address must be one Brevo has verified, or messages are
rejected at submission rather than bouncing later.

---

## First deploy

### 1 · Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Fill in `project_id`, `supabase_project_ref`, `mail_username` and `mail_from`.
No secrets go in this file.

### 2 · Apply

```bash
terraform init
terraform apply
```

This creates both Cloud Run services with a placeholder image, the Artifact
Registry repo, seven **empty** secrets, the Workload Identity Federation setup
for CI, and two **paused** scheduler jobs.

Both services get their URLs now, which is why nothing here needs a second
apply: Terraform already knows the console's URL and puts it in the API's
`LIZMO_CORS_ORIGINS`.

### 3 · Fill in the secrets

Terraform creates them empty on purpose — any value it writes ends up in
plaintext in the state file. Cloud Run will not start until each has a version.

`read -rs` does not echo, so nothing lands in your shell history:

```bash
printf 'jdbc:postgresql://aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres?sslmode=require' \
  | gcloud secrets versions add lizmo-db-url --data-file=-

printf 'postgres.YOUR_PROJECT_REF' | gcloud secrets versions add lizmo-db-user --data-file=-

read -rs V && printf '%s' "$V" | gcloud secrets versions add lizmo-db-password       --data-file=- && unset V
read -rs V && printf '%s' "$V" | gcloud secrets versions add lizmo-storage-access-key --data-file=- && unset V
read -rs V && printf '%s' "$V" | gcloud secrets versions add lizmo-storage-secret-key --data-file=- && unset V
read -rs V && printf '%s' "$V" | gcloud secrets versions add lizmo-mail-password      --data-file=- && unset V

openssl rand -base64 48 | gcloud secrets versions add lizmo-jwt-secret --data-file=-
```

The database URL carries **no credentials** — they are their own secrets.
pgjdbc lets URL query parameters override the properties Spring supplies, so a
password embedded there silently wins over `DB_PASSWORD`; keeping it out also
means Supabase's symbol-heavy generated password never has to be
percent-encoded.

### 4 · Deploy the API

```bash
gcloud auth configure-docker asia-southeast1-docker.pkg.dev

docker build -t asia-southeast1-docker.pkg.dev/PROJECT/lizmo/api:v1 ./backend
docker push  asia-southeast1-docker.pkg.dev/PROJECT/lizmo/api:v1

gcloud run deploy lizmo-api \
  --image asia-southeast1-docker.pkg.dev/PROJECT/lizmo/api:v1 \
  --region asia-southeast1
```

The first start runs all fifteen Flyway migrations against the empty Supabase
database. `baseline-on-migrate` is **off** in the prod profile, so pointing this
at a non-empty database fails loudly instead of assuming the migrations were
already applied.

Check it:

```bash
curl "$(terraform output -raw api_url)/actuator/health"
```

### 5 · Deploy the console

The console is a Flutter web bundle, so the API's URL is **compiled in** — there
is no runtime environment for it to read.

```bash
API_URL=$(terraform output -raw api_url)

docker build -f Dockerfile.flutter-web \
  --build-arg APP=admin \
  --build-arg API_BASE_URL="$API_URL" \
  -t asia-southeast1-docker.pkg.dev/PROJECT/lizmo/admin:v1 .
docker push asia-southeast1-docker.pkg.dev/PROJECT/lizmo/admin:v1

gcloud run deploy lizmo-admin \
  --image asia-southeast1-docker.pkg.dev/PROJECT/lizmo/admin:v1 \
  --region asia-southeast1 --port 80
```

Run this from the repo root, not from `admin/` — both apps depend on
`packages/` through path dependencies.

### 6 · Make yourself an administrator

No endpoint grants admin, deliberately: a compromised API cannot mint itself
one. Sign up normally in the app first, then in Supabase's SQL editor:

```sql
insert into platform_admins (user_id, created_at)
values ('<your user id>', now());
```

Sign in again afterwards — profiles are baked into an access token when it is
issued, so the one you already hold still says TENANT.

### 7 · Point a phone at it

```bash
flutter run --dart-define=LIZMO_API_BASE_URL=https://lizmo-api-xxxx.run.app
```

Note that `ApiConfig` currently hardcodes a LAN address for Android; the
`--dart-define` overrides it.

---

## Continuous deploy

`.github/workflows/deploy.yml` and `deploy-admin.yml` are manual
(`workflow_dispatch`) until the stack has been deployed by hand once —
continuous deploy to infrastructure that has never worked is a poor way to
discover its problems.

Both authenticate with Workload Identity Federation, so no service account key
exists to leak. Set three repository variables:

| Variable | Where from |
|---|---|
| `WIF_PROVIDER` | `terraform output github_workload_identity_provider` |
| `WIF_SERVICE_ACCOUNT` | `terraform output github_deployer_service_account` |
| `GCP_PROJECT_ID` | your project id |

---

## Still to do

- **The scheduler jobs are paused.** `/internal/jobs/platform-billing-snapshot`
  and `/internal/jobs/platform-billing-enforcement` do not exist, and must
  verify the scheduler's OIDC token when they do — living under `/internal/` is
  not protection on a public service. Resume with `gcloud scheduler jobs resume`;
  Terraform ignores the flag afterwards.
- **No custom domain.** Both services use their generated `*.run.app` URLs, and
  `LIZMO_INVITE_BASE_URL` points at a console path that nothing serves. The
  invitation email carries the token as text beside the link, and that is the
  path that works. A domain plus App Links / Universal Links plus an accept
  screen is what makes the link itself work.
- **No state backend.** Local state is fine for one operator; switch to the GCS
  backend in `versions.tf` before CI or a second person runs `apply`.
- **Cold starts.** `min_instances = 0` means the first request after idle waits
  10–20s for Spring Boot. Raise it when that matters more than the bill.
