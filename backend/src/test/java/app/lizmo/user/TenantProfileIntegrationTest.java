package app.lizmo.user;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * A tenant's own profile.
 *
 * <p>The isolation tests matter most here for a different reason than the
 * property ones: this is the most personal data the app holds, and the endpoint
 * only ever serves the caller their own.
 */
class TenantProfileIntegrationTest extends IntegrationTest {

    private String tenantToken;
    private String otherTenantToken;
    private String landlordOnlyToken;

    @BeforeEach
    void signUpEveryone() throws Exception {
        tenantToken = accounts.tenant("ana").token();
        otherTenantToken = accounts.tenant("bea").token();
        landlordOnlyToken = accounts.landlord("elena").token();
    }



    private void save(String token, String body) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }

    @Test
    void a_new_tenant_starts_with_an_empty_profile() throws Exception {
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.birthdate").doesNotExist())
                .andExpect(jsonPath("$.emergencyContactName").doesNotExist())
                // Nothing filled in, so nothing to sign a lease against.
                .andExpect(jsonPath("$.readyForALease").value(false));
    }

    @Test
    void a_tenant_can_fill_in_and_read_back_their_details() throws Exception {
        save(tenantToken, """
                {"birthdate":"1998-04-12",
                 "permanentAddress":"Brgy. San Isidro, Naga City",
                 "occupation":"Nurse at Bicol Medical Center",
                 "emergencyContactName":"Rosa Dela Cruz",
                 "emergencyContactRelationship":"Mother",
                 "emergencyContactPhone":"09171234567",
                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                """);

        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.birthdate").value("1998-04-12"))
                .andExpect(jsonPath("$.occupation").value("Nurse at Bicol Medical Center"))
                .andExpect(jsonPath("$.emergencyContactRelationship").value("Mother"))
                .andExpect(jsonPath("$.idType").value("PHILSYS"))
                // Not ready: the photographs are the other half, and they are
                // asserted where documents live.
                .andExpect(jsonPath("$.readyForALease").value(false));
    }

    @Test
    void a_half_finished_profile_is_saved_rather_than_refused() throws Exception {
        // A tenant filling this in on a phone skips what they can. Refusing the
        // lot would leave nothing saved at all.
        save(tenantToken, """
                {"occupation":"Student"}
                """);

        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.occupation").value("Student"))
                .andExpect(jsonPath("$.readyForALease").value(false));
    }

    @Test
    void the_details_a_lease_needs_are_an_emergency_contact_and_an_id() throws Exception {
        // Everything but the ID.
        save(tenantToken, """
                {"emergencyContactName":"Rosa Dela Cruz",
                 "emergencyContactPhone":"09171234567",
                 "birthdate":"1998-04-12",
                 "permanentAddress":"Naga City","occupation":"Nurse"}
                """);

        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.readyForALease").value(false));

        save(tenantToken, """
                {"emergencyContactName":"Rosa Dela Cruz",
                 "emergencyContactPhone":"09171234567",
                 "idType":"UMID","idNumber":"0111-2222222-3"}
                """);

        // Still false, and correctly so: every detail is filled in, but an ID
        // number typed into a form is not an ID anybody has seen. The
        // photographs complete it, in TenantDocumentIntegrationTest.
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.readyForALease").value(false));
    }

    @Test
    void a_blank_field_clears_it_rather_than_storing_spaces() throws Exception {
        save(tenantToken, """
                {"occupation":"Nurse"}
                """);

        save(tenantToken, """
                {"occupation":"   "}
                """);

        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.occupation").doesNotExist());
    }

    @Test
    void a_birthdate_in_the_future_is_refused() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"birthdate":"2999-01-01"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields.birthdate").exists());
    }

    @Test
    void an_unknown_id_type_is_refused_by_name() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idType":"LIBRARY_CARD"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("PHILSYS")));
    }

    @Test
    void one_tenant_never_sees_another() throws Exception {
        save(tenantToken, """
                {"occupation":"Nurse","emergencyContactName":"Rosa Dela Cruz"}
                """);

        // The endpoint is addressed as "me". There is no id to pass, which is
        // the point: this is the most personal data the app holds.
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + otherTenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.occupation").doesNotExist())
                .andExpect(jsonPath("$.emergencyContactName").doesNotExist());
    }

    @Test
    void a_landlord_account_still_has_its_own_tenant_profile() throws Exception {
        // Registration gives every account a tenant profile, landlords
        // included — the roles are additive, so this is not an error case.
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + landlordOnlyToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.readyForALease").value(false));
    }

    @Test
    void signing_out_of_the_endpoint_is_not_optional() throws Exception {
        mvc.perform(get("/api/v1/me/tenant-profile"))
                .andExpect(status().isUnauthorized());
    }
}
