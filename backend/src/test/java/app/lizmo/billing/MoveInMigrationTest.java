package app.lizmo.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import javax.imageio.ImageIO;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;

/**
 * V43 against a lease written before it: its deposit recorded once, as
 * received at move-in, with the payment behind it.
 *
 * <p>The suite's own database is migrated from empty, where the backfill has
 * nothing to do. So this builds a second schema in the same database, takes it
 * to V42, copies in one tenancy made through the API -- as it would have been
 * stored before V43 -- and only then runs V43 over it.
 */
class MoveInMigrationTest extends IntegrationTest {

    private static final String SCHEMA = "before_move_in_charges";

    @Autowired
    private DataSource dataSource;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void an_older_deposit_is_recorded_as_received_at_move_in() throws Exception {
        Tenancy made = tenancyWithADeposit();

        try {
            migrate("42");
            copyIn(made);
            migrate("43");

            List<Map<String, Object>> deposits = jdbc.queryForList(
                    "SELECT * FROM " + SCHEMA + ".billing_periods WHERE lease_id = ?::uuid"
                            + " AND kind = 'DEPOSIT'", made.lease());
            assertThat(deposits).hasSize(1);
            Map<String, Object> deposit = deposits.get(0);
            assertThat(deposit.get("period_label")).isEqualTo("Security deposit");
            assertThat((BigDecimal) deposit.get("amount_due")).isEqualByComparingTo("5000");
            assertThat((BigDecimal) deposit.get("amount_paid")).isEqualByComparingTo("5000");
            assertThat(deposit.get("status")).isEqualTo("PAID");

            // The payment behind it, so the period's amount_paid agrees with
            // what was paid against it.
            List<Map<String, Object>> paid = jdbc.queryForList(
                    "SELECT * FROM " + SCHEMA + ".payments WHERE billing_period_id = ?",
                    deposit.get("id"));
            assertThat(paid).hasSize(1);
            assertThat(paid.get(0).get("status")).isEqualTo("CONFIRMED");
            assertThat((BigDecimal) paid.get(0).get("amount_paid")).isEqualByComparingTo("5000");
            assertThat(paid.get(0).get("submitted_by").toString()).isEqualTo(made.tenant());
            assertThat(paid.get(0).get("verified_by").toString()).isEqualTo(made.landlord());

            // And the lease keeps the old rules: no month is suddenly due.
            assertThat(jdbc.queryForObject(
                    "SELECT charged_at_move_in FROM " + SCHEMA + ".leases WHERE id = ?::uuid",
                    Boolean.class, made.lease())).isFalse();
        } finally {
            jdbc.execute("DROP SCHEMA IF EXISTS " + SCHEMA + " CASCADE");
        }
    }

    // ---- fixtures ----------------------------------------------------------------

    private record Tenancy(String lease, String tenant, String landlord,
                           String property, String unit, String bed) {
    }

    private void migrate(String version) {
        Flyway.configure()
                .dataSource(dataSource)
                .schemas(SCHEMA)
                .locations("classpath:db/migration")
                .target(version)
                .load()
                .migrate();
    }

    /**
     * Copies one tenancy's rows from the suite's schema into the old one,
     * column for column as the old schema has them -- the leases table there
     * has no charged_at_move_in yet -- and without the conversation it came
     * from, which the copy does not need.
     */
    private void copyIn(Tenancy made) {
        copy("users", "id IN ('%s'::uuid, '%s'::uuid)".formatted(made.tenant(), made.landlord()));
        copy("landlord_profiles", "user_id = '%s'::uuid".formatted(made.landlord()));
        copy("tenant_profiles", "user_id = '%s'::uuid".formatted(made.tenant()));
        copy("properties", "id = '%s'::uuid".formatted(made.property()));
        copy("units", "id = '%s'::uuid".formatted(made.unit()));
        copy("beds", "id = '%s'::uuid".formatted(made.bed()));
        copy("leases", "id = '%s'::uuid".formatted(made.lease()));
    }

    private void copy(String table, String where) {
        List<String> columns = jdbc.queryForList(
                "SELECT column_name FROM information_schema.columns"
                        + " WHERE table_schema = ? AND table_name = ? ORDER BY ordinal_position",
                String.class, SCHEMA, table);
        String into = String.join(", ", columns);
        String from = columns.stream()
                .map(column -> column.equals("inquiry_id") ? "NULL" : column)
                .collect(Collectors.joining(", "));
        jdbc.update("INSERT INTO %s.%s (%s) SELECT %s FROM public.%s WHERE %s"
                .formatted(SCHEMA, table, into, from, table, where));
    }

    private Tenancy tenancyWithADeposit() throws Exception {
        var landlord = accounts.landlord("elena");
        var tenant = accounts.tenant("ana");
        makeReadyForALease(tenant.token());

        String property = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlord.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        String unit = json.readTree(mvc.perform(post("/api/v1/properties/" + property + "/units")
                        .header("Authorization", "Bearer " + landlord.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        String bed = json.readTree(mvc.perform(get("/api/v1/units/" + unit + "/beds")
                        .header("Authorization", "Bearer " + landlord.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        String lease = json.readTree(letRoom(
                landlord.token(),
                tenant.token(),
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unit, bed),
                "{\"rentAmount\":2500.00,\"startDate\":\"%s\",\"depositAmount\":5000.00}"
                        .formatted(LocalDate.now().minusMonths(2))))
                .get("id").asText();

        return new Tenancy(lease, tenant.id().toString(), landlord.id().toString(),
                property, unit, bed);
    }

    private void makeReadyForALease(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                                """))
                .andExpect(status().isOk());

        for (String kind : new String[] {"VALID_ID", "TENANT_PHOTO"}) {
            mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                            .file(new MockMultipartFile("file", "p.jpg", "image/jpeg", photo()))
                            .param("docType", kind)
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isCreated());
        }
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
