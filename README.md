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
- Postgres: `localhost:5433`, db/user `lizmo`, password `lizmo_dev`
- LocalStack S3: `http://localhost:4567`, bucket `lizmo-uploads-local`

Every host port here is non-default, because the defaults are already taken on
this machine: 8080/8081 and 4566 by the `admissions-ph` stack, and 5432 by a
native PostgreSQL service. Container-internal ports are unchanged (8080, 4566,
5432), so nothing inside the compose network is affected — only host clients
such as DBeaver need the remapped numbers.

Flyway applies `V1__init.sql` on API startup, so the schema is created automatically.

## Run the API outside Docker

Start just the dependencies, then run the app against them:

```bash
docker compose up -d postgres localstack
```

```bash
cd backend && ./gradlew bootRun
```

Point it at the containers explicitly — `application.yml` defaults to port 5432,
which on this machine reaches a native PostgreSQL service rather than ours:

```bash
DB_URL=jdbc:postgresql://localhost:5433/lizmo AWS_S3_ENDPOINT=http://localhost:4567 ./gradlew bootRun
```

## Notes

- Secrets in `docker-compose.yml` are local-dev only. Production values come from Secrets Manager per the tech spec.
- JPA runs with `ddl-auto: validate` — the schema is owned by Flyway, never by Hibernate.
