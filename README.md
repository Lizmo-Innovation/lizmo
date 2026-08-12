# Lizmo

Rental management for individual Philippine landlords — whole units and bedspaces.

See [Lizmo_Product_Spec_v1.md](docs/Lizmo_Product_Spec_v1.md) and [Lizmo_Tech_Spec_v1.md](docs/Lizmo_Tech_Spec_v1.md).
UI work follows [lizmo_design_language_v2.html](docs/lizmo_design_language_v2.html) (canonical design language).

## Layout

```
backend/                 Spring Boot 3.3 / Java 21 API (Gradle)
  src/main/resources/db/migration/   Flyway migrations
infra/localstack/        LocalStack init scripts (creates the S3 bucket)
docker-compose.yml       postgres + localstack + api
```

## Run the stack

```bash
docker compose up --build
```

- API: http://localhost:8082 (health at `/actuator/health`)
- Postgres: `localhost:5432`, db/user `lizmo`, password `lizmo_dev`
- LocalStack S3: `http://localhost:4567`, bucket `lizmo-uploads-local`

Host ports 8082/4567 are non-default: 8080, 8081, and 4566 are occupied by the
`admissions-ph` stack on this machine. Container-internal ports are unchanged
(8080 and 4566), so nothing inside the compose network is affected.

Flyway applies `V1__init.sql` on API startup, so the schema is created automatically.

## Run the API outside Docker

Start just the dependencies, then run the app against them:

```bash
docker compose up -d postgres localstack
```

```bash
cd backend && ./gradlew bootRun
```

Defaults in `application.yml` already point at `localhost:5432`. Set
`AWS_S3_ENDPOINT=http://localhost:4567` to reach the containerized LocalStack.

## Notes

- Secrets in `docker-compose.yml` are local-dev only. Production values come from Secrets Manager per the tech spec.
- JPA runs with `ddl-auto: validate` — the schema is owned by Flyway, never by Hibernate.
