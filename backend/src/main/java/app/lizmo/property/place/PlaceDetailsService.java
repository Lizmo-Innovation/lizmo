package app.lizmo.property.place;

import app.lizmo.property.PropertyAccess;
import app.lizmo.property.place.LandlordCard.ReplySpeed;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A place's details, and the landlord as a stranger sees them.
 */
@Service
public class PlaceDetailsService {

    /** Fewer than this and one slow day would stand for the landlord. */
    static final int ENOUGH_CONVERSATIONS = 3;

    /** The most recent conversations that say how fast they answer now. */
    private static final int RECENT = 20;

    /**
     * Somebody asked and has not been answered: counted once they have waited
     * this long, as a wait at least this long. Before then it might yet be
     * answered within the hour, and counting it would be unfair.
     */
    private static final Duration UNANSWERED_COUNTS_AFTER = Duration.ofDays(1);

    private static final ZoneId PHILIPPINES = ZoneId.of("Asia/Manila");

    private final PlaceDetailsRepository details;
    private final PropertyAccess access;
    private final UserRepository users;
    private final JdbcTemplate jdbc;
    private final Clock clock;

    public PlaceDetailsService(
            PlaceDetailsRepository details,
            PropertyAccess access,
            UserRepository users,
            JdbcTemplate jdbc,
            Clock clock) {
        this.details = details;
        this.access = access;
        this.users = users;
        this.jdbc = jdbc;
        this.clock = clock;
    }

    /** As the landlord set them; every field null where nothing is said. */
    @Transactional(readOnly = true)
    public PlaceDetailsDto forLandlord(UUID propertyId, UUID landlordId) {
        access.readable(propertyId, landlordId);
        return of(propertyId);
    }

    /**
     * Replaced whole. Allowed while the property is locked: describing a
     * place grows nothing a landlord is billed for.
     */
    @Transactional
    public PlaceDetailsDto save(UUID propertyId, UUID landlordId, PlaceDetailsDto command) {
        access.readable(propertyId, landlordId);
        PlaceDetails place = details.findById(propertyId)
                .orElseGet(() -> new PlaceDetails(propertyId));
        place.set(command);
        return PlaceDetailsDto.of(details.save(place));
    }

    /** For anybody looking at the place, with nothing to check first. */
    @Transactional(readOnly = true)
    public PlaceDetailsDto of(UUID propertyId) {
        return PlaceDetailsDto.of(details.findById(propertyId).orElse(null));
    }

    /** The landlord: first name and initial, when they joined, how fast they answer. */
    @Transactional(readOnly = true)
    public LandlordCard landlord(UUID landlordId) {
        User user = users.findById(landlordId).orElse(null);
        if (user == null) {
            return null;
        }
        return new LandlordCard(
                shortName(user.getName()),
                user.getCreatedAt() == null
                        ? null
                        : user.getCreatedAt().atZone(PHILIPPINES).toLocalDate().withDayOfMonth(1),
                replySpeed(landlordId));
    }

    /** "Elena B." out of "Elena Bautista". */
    static String shortName(String name) {
        if (name == null || name.isBlank()) {
            return null;
        }
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0];
        }
        return parts[0] + " " + Character.toUpperCase(parts[parts.length - 1].charAt(0)) + ".";
    }

    /**
     * How long, typically, from somebody asking to the landlord answering,
     * over their recent conversations.
     *
     * <p>The middle wait rather than the average, so one weekend away does not
     * make a prompt landlord look slow. A conversation never answered counts as
     * long as it has waited, once it has waited a day.
     */
    ReplySpeed replySpeed(UUID landlordId) {
        Instant now = clock.instant();
        List<Duration> waits = new ArrayList<>();
        jdbc.query("""
                SELECT asked.at AS asked,
                       (SELECT MIN(m.sent_at) FROM inquiry_messages m
                         WHERE m.inquiry_id = asked.inquiry_id
                           AND m.sender_id = ?
                           AND m.sent_at >= asked.at) AS answered
                  FROM (SELECT i.id AS inquiry_id,
                               (SELECT MIN(m.sent_at) FROM inquiry_messages m
                                 WHERE m.inquiry_id = i.id
                                   AND m.sender_id = i.tenant_id) AS at
                          FROM inquiries i
                          JOIN properties p ON p.id = i.property_id
                         WHERE p.landlord_id = ?) asked
                 WHERE asked.at IS NOT NULL
                 ORDER BY asked.at DESC
                 LIMIT ?
                """, row -> {
            Instant asked = row.getTimestamp("asked").toInstant();
            java.sql.Timestamp answered = row.getTimestamp("answered");
            if (answered != null) {
                waits.add(Duration.between(asked, answered.toInstant()));
            } else if (Duration.between(asked, now).compareTo(UNANSWERED_COUNTS_AFTER) >= 0) {
                waits.add(Duration.between(asked, now));
            }
        }, landlordId, landlordId, RECENT);

        if (waits.size() < ENOUGH_CONVERSATIONS) {
            return null;
        }
        Collections.sort(waits);
        Duration middle = waits.get(waits.size() / 2);
        if (middle.compareTo(Duration.ofHours(1)) <= 0) {
            return ReplySpeed.WITHIN_AN_HOUR;
        }
        if (middle.compareTo(Duration.ofDays(1)) <= 0) {
            return ReplySpeed.WITHIN_A_DAY;
        }
        return ReplySpeed.WITHIN_DAYS;
    }
}
