# Lizmo — GCP infrastructure

Terraform for the production stack. Replaces the AWS CloudFormation design in
tech spec §6, which assumed ECS Fargate, RDS and an ALB.

## Shape

```
Flutter apps ──HTTPS──> Cloud Run (lizmo-api, asia-southeast1)
                            ├── Secret Manager   (DB URL, JWT key)
                            ├── Cloud Storage    (uploads, signed URLs)
                            └── external Postgres (Neon / Supabase, over SSL)

Cloud Scheduler ──OIDC──> /internal/jobs/*   (billing snapshot, enforcement)
```

## Why this differs from the tech spec

| Tech spec (AWS) | Here (GCP) | Reason |
|---|---|---|
| ECS Fargate + ALB | Cloud Run | Scales to zero and terminates TLS itself; an external HTTPS load balancer is billable |
| RDS PostgreSQL | External managed Postgres | Cloud SQL is **not** in GCP's always-free tier |
| S3 | Cloud Storage | Direct equivalent |
| Secrets Manager | Secret Manager | Direct equivalent |
| Spring `@Scheduled` | Cloud Scheduler | With `min_instances = 0` an in-process scheduler never fires while asleep |

## Cost

Everything here sits in the always-free tier except Cloud Storage, which is
free only in US regions — in `asia-southeast1` it costs a few cents a month at
this scale. That is a deliberate trade for upload latency.

The one real cost lever is `min_instances`. At `0` you stay free but pay a
10–20s Spring Boot cold start on the first request after idle. At `1` the
service is always warm and always billed.

## First deploy

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

cp terraform.tfvars.example terraform.tfvars   # fill in project_id
terraform init
terraform apply
```

Terraform creates the secrets **empty** — deliberately, so their values never
land in state. Cloud Run will not start until both have a version:

```bash
printf 'jdbc:postgresql://USER:PASS@HOST/DB?sslmode=require' \
  | gcloud secrets versions add lizmo-db-url --data-file=-

openssl rand -base64 48 | gcloud secrets versions add lizmo-jwt-secret --data-file=-
```

Then build and push the API image, and deploy it:

```bash
gcloud auth configure-docker asia-southeast1-docker.pkg.dev

docker build -t asia-southeast1-docker.pkg.dev/PROJECT/lizmo/api:v1 ./backend
docker push asia-southeast1-docker.pkg.dev/PROJECT/lizmo/api:v1

gcloud run deploy lizmo-api --image asia-southeast1-docker.pkg.dev/PROJECT/lizmo/api:v1 --region asia-southeast1
```

Terraform ignores changes to the running image, so deploys do not fight with
`terraform apply`.

## Still to do

- `/internal/jobs/*` endpoints do not exist yet, and must verify the scheduler's
  OIDC token — living under `/internal/` is not protection on a public service.
- The API needs a `prod` Spring profile reading `DB_URL`, `JWT_SECRET` and
  `GCS_BUCKET`, and a Cloud Storage client replacing the S3 one.
- No state backend. Local state is fine for one operator; switch to the GCS
  backend in `versions.tf` before CI or a second person runs `apply`.
- No custom domain — the app uses the generated `*.run.app` URL.
