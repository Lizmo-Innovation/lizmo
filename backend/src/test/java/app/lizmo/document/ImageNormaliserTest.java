package app.lizmo.document;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.lizmo.common.ApiException;
import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.ExifIFD0Directory;
import com.drew.metadata.exif.GpsDirectory;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * What arrives from a phone, and what is allowed to reach the bucket.
 *
 * <p>The orientation cases are the reason this class exists as a unit test
 * rather than being covered only through the endpoint. Getting 5 and 7 wrong
 * produces an image that is plausible at a glance and mirrored — the sort of
 * bug that ships.
 */
class ImageNormaliserTest {

    private final ImageNormaliser normaliser = new ImageNormaliser();

    @Test
    void a_photograph_survives_being_normalised() throws Exception {
        byte[] out = normaliser.normalise(jpeg(colouredCorners(40, 20), 1));

        BufferedImage image = decode(out);
        assertThat(image.getWidth()).isEqualTo(40);
        assertThat(image.getHeight()).isEqualTo(20);
    }

    @Test
    void nothing_that_was_in_the_metadata_comes_out_the_other_side() throws Exception {
        byte[] withExif = jpeg(colouredCorners(40, 20), 6);
        // The input really does carry what the output must not.
        assertThat(orientationOf(withExif)).isEqualTo(6);

        byte[] out = normaliser.normalise(withExif);

        Metadata metadata = ImageMetadataReader.readMetadata(new ByteArrayInputStream(out));
        assertThat(metadata.getFirstDirectoryOfType(ExifIFD0Directory.class)).isNull();
        // Where a home address hides on an ID photographed at the kitchen table.
        assertThat(metadata.getFirstDirectoryOfType(GpsDirectory.class)).isNull();
    }

    /**
     * The tag is stripped, so the pixels have to carry what it said. A portrait
     * photo whose orientation was dropped without being applied is a photo on
     * its side.
     */
    @ParameterizedTest(name = "orientation {0} puts the marked corner at {1},{2}")
    @CsvSource({
        // orientation, expected x, expected y of the corner that started top-left
        "1, 0, 0",
        "2, 39, 0",
        "3, 39, 19",
        "4, 0, 19",
        "5, 0, 0",
        "6, 19, 0",
        "7, 19, 39",
        "8, 0, 39",
    })
    void the_pixels_are_turned_the_way_the_tag_said(int orientation, int x, int y)
            throws Exception {
        BufferedImage source = colouredCorners(40, 20);
        byte[] out = normaliser.normalise(jpeg(source, orientation));

        BufferedImage image = decode(out);
        // 5 to 8 turn the image on its side, so the canvas swaps dimensions.
        boolean swapsAxes = orientation >= 5;
        assertThat(image.getWidth()).isEqualTo(swapsAxes ? 20 : 40);
        assertThat(image.getHeight()).isEqualTo(swapsAxes ? 40 : 20);

        assertThat(isRed(image.getRGB(x, y)))
                .as("the corner marked red should have moved to %d,%d", x, y)
                .isTrue();
    }

    @Test
    void a_photograph_from_a_modern_phone_is_brought_down_to_size() throws Exception {
        // Roughly 12MP, which is what a mid-range phone shoots and far more
        // than anyone needs to read an ID.
        byte[] out = normaliser.normalise(jpeg(colouredCorners(4000, 3000), 1));

        BufferedImage image = decode(out);
        assertThat(image.getWidth()).isEqualTo(2000);
        // The shape is kept: an ID squashed to a square is unreadable.
        assertThat(image.getHeight()).isEqualTo(1500);
    }

    @Test
    void a_small_photograph_is_left_alone_rather_than_stretched() throws Exception {
        byte[] out = normaliser.normalise(jpeg(colouredCorners(300, 200), 1));

        BufferedImage image = decode(out);
        assertThat(image.getWidth()).isEqualTo(300);
        assertThat(image.getHeight()).isEqualTo(200);
    }

    @Test
    void a_transparent_png_is_flattened_rather_than_inverted() throws Exception {
        BufferedImage transparent =
                new BufferedImage(20, 20, BufferedImage.TYPE_INT_ARGB);
        transparent.createGraphics().dispose();
        ByteArrayOutputStream png = new ByteArrayOutputStream();
        ImageIO.write(transparent, "png", png);

        // JPEG has no alpha channel; writing one produces wrong colours rather
        // than an error, so this would fail silently if it failed at all.
        byte[] out = normaliser.normalise(png.toByteArray());

        assertThat(decode(out).getWidth()).isEqualTo(20);
    }

    @Test
    void something_that_is_not_an_image_is_refused_with_advice() {
        assertThatThrownBy(() -> normaliser.normalise("not a photograph".getBytes(
                StandardCharsets.UTF_8)))
                .isInstanceOf(ApiException.class)
                // Most often HEIC from an iPhone, so the message says what to
                // upload rather than only that this failed.
                .hasMessageContaining("JPEG or PNG");
    }

    @Test
    void a_damaged_metadata_block_does_not_fail_the_upload() throws Exception {
        byte[] jpeg = jpeg(colouredCorners(40, 20), 1);
        byte[] corrupted = withExifSegment(jpeg, new byte[] {0x45, 0x78, 0x69, 0x66, 0, 0, 1, 2});

        // A tenant cannot see or fix a broken EXIF block, and the photograph
        // itself is fine.
        assertThat(normaliser.normalise(corrupted)).isNotEmpty();
    }

    // ---- helpers ----------------------------------------------------------

    /**
     * An image whose top-left corner is red and whose other three are distinct,
     * so a rotation or a mirror is visible in a single pixel read.
     */
    private static BufferedImage colouredCorners(int width, int height) {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, width, height);
        g.dispose();

        int block = Math.max(1, Math.min(width, height) / 4);
        fill(image, 0, 0, block, Color.RED);
        fill(image, width - block, 0, block, Color.GREEN);
        fill(image, 0, height - block, block, Color.BLUE);
        fill(image, width - block, height - block, block, Color.BLACK);
        return image;
    }

    private static void fill(BufferedImage image, int x, int y, int size, Color colour) {
        for (int dy = 0; dy < size; dy++) {
            for (int dx = 0; dx < size; dx++) {
                image.setRGB(x + dx, y + dy, colour.getRGB());
            }
        }
    }

    /** JPEG is lossy, so the corner is identified by hue rather than equality. */
    private static boolean isRed(int rgb) {
        int r = (rgb >> 16) & 0xFF;
        int g = (rgb >> 8) & 0xFF;
        int b = rgb & 0xFF;
        return r > 150 && g < 100 && b < 100;
    }

    private static BufferedImage decode(byte[] bytes) throws IOException {
        return ImageIO.read(new ByteArrayInputStream(bytes));
    }

    private static int orientationOf(byte[] bytes) throws Exception {
        Metadata metadata = ImageMetadataReader.readMetadata(new ByteArrayInputStream(bytes));
        return metadata.getFirstDirectoryOfType(ExifIFD0Directory.class)
                .getInt(ExifIFD0Directory.TAG_ORIENTATION);
    }

    /** A JPEG carrying an EXIF orientation, as a phone would produce. */
    private static byte[] jpeg(BufferedImage image, int orientation) throws IOException {
        ByteArrayOutputStream plain = new ByteArrayOutputStream();
        ImageIO.write(image, "jpeg", plain);
        return withExifSegment(plain.toByteArray(), exifPayload(orientation));
    }

    /**
     * A minimal EXIF payload: a TIFF header and one IFD entry, the orientation.
     * ImageIO cannot write EXIF, so a realistic input has to be assembled here.
     */
    private static byte[] exifPayload(int orientation) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.writeBytes("Exif".getBytes(StandardCharsets.US_ASCII));
        out.write(0);
        out.write(0);

        // TIFF header, little-endian, first IFD at offset 8.
        out.writeBytes(new byte[] {'I', 'I', 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00});
        // One entry.
        out.writeBytes(new byte[] {0x01, 0x00});
        // Tag 0x0112 (orientation), type 3 (SHORT), count 1, then the value
        // padded to the four bytes an IFD entry always spends.
        out.writeBytes(new byte[] {0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00});
        out.write(orientation & 0xFF);
        out.write(0);
        out.write(0);
        out.write(0);
        // No next IFD.
        out.writeBytes(new byte[] {0, 0, 0, 0});
        return out.toByteArray();
    }

    /** Splices an APP1 segment in immediately after the start-of-image marker. */
    private static byte[] withExifSegment(byte[] jpeg, byte[] payload) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(jpeg[0]);
        out.write(jpeg[1]);

        int length = payload.length + 2;
        out.write(0xFF);
        out.write(0xE1);
        out.write((length >> 8) & 0xFF);
        out.write(length & 0xFF);
        out.writeBytes(payload);

        out.write(jpeg, 2, jpeg.length - 2);
        return out.toByteArray();
    }
}
