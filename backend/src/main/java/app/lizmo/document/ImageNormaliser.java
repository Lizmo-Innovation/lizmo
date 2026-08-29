package app.lizmo.document;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.ExifIFD0Directory;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.MemoryCacheImageOutputStream;
import org.springframework.stereotype.Component;

/**
 * Turns whatever a phone uploaded into a plain JPEG with no metadata.
 *
 * <p>The stripping is done by decoding to pixels and re-encoding, not by
 * deleting EXIF fields. Deleting fields leaves the ones nobody thought of --
 * XMP, IPTC, maker notes, and the embedded thumbnail, which is its own image
 * and has been caught carrying the GPS tag that was scrubbed from its parent.
 * Pixels in, pixels out: there is nothing left to miss.
 *
 * <p>This matters more here than on a property photo. An ID card photographed
 * at home carries the home's coordinates, and the tenant is handing it to
 * their landlord.
 */
@Component
public class ImageNormaliser {

    /**
     * Enough to read the small print on an ID, far less than a modern phone
     * shoots. A 12MP photo is around 4MB; this lands near 400KB.
     */
    private static final int MAX_EDGE = 2000;

    private static final float JPEG_QUALITY = 0.85f;

    public static final String OUTPUT_CONTENT_TYPE = "image/jpeg";

    /**
     * @return re-encoded JPEG bytes, carrying no metadata of any kind
     * @throws ApiException if the bytes are not an image this can decode
     */
    public byte[] normalise(byte[] original) {
        // Read before decoding: the orientation tag is about to stop existing,
        // and without applying it a portrait photo is saved on its side.
        int orientation = readOrientation(original);

        BufferedImage decoded = decode(original);
        // Scaled before rotating: uniform scaling and rotation commute, and
        // turning a 400KB image is a great deal cheaper than turning a 4MB one.
        BufferedImage scaled = scaleWithin(decoded, MAX_EDGE);
        BufferedImage upright = applyOrientation(scaled, orientation);

        return encodeJpeg(upright);
    }

    private static BufferedImage decode(byte[] bytes) {
        BufferedImage image;
        try {
            image = ImageIO.read(new ByteArrayInputStream(bytes));
        } catch (IOException e) {
            image = null;
        }
        if (image == null) {
            // Most often HEIC, which is what an iPhone shoots by default and
            // which ImageIO cannot read without native libraries. The client
            // converts before uploading; this is the backstop, and it names
            // what to do rather than saying "invalid file".
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file could not be read as an image. Please upload a JPEG or PNG.");
        }
        return image;
    }

    /**
     * The EXIF orientation tag, or 1 (upright) when there is none.
     *
     * <p>Unreadable metadata is not an error. A photo with a damaged EXIF block
     * is still a photo, and refusing it would fail the upload over something
     * the tenant cannot see or fix.
     */
    private static int readOrientation(byte[] bytes) {
        try {
            Metadata metadata = ImageMetadataReader.readMetadata(new ByteArrayInputStream(bytes));
            ExifIFD0Directory dir = metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);
            if (dir != null && dir.containsTag(ExifIFD0Directory.TAG_ORIENTATION)) {
                return dir.getInt(ExifIFD0Directory.TAG_ORIENTATION);
            }
        } catch (Exception e) {
            // Falls through to upright.
        }
        return 1;
    }

    /**
     * Turns the pixels the way up the photograph was taken.
     *
     * <p>Built from a quarter-turn and a horizontal flip rather than one
     * composed transform. The eight EXIF orientations are notoriously easy to
     * get subtly wrong -- 5 and 7 especially, which are mirrored as well as
     * turned -- and two operations that are each obviously right can be
     * checked a pixel at a time. There is a test per orientation.
     */
    private static BufferedImage applyOrientation(BufferedImage image, int orientation) {
        return switch (orientation) {
            case 2 -> flipHorizontally(image);
            case 3 -> quarterTurns(image, 2);
            case 4 -> quarterTurns(flipHorizontally(image), 2);
            case 5 -> flipHorizontally(quarterTurns(image, 1));
            case 6 -> quarterTurns(image, 1);
            case 7 -> flipHorizontally(quarterTurns(image, 3));
            case 8 -> quarterTurns(image, 3);
            // 1 is upright, and anything outside 1..8 is a tag we do not
            // believe. Leaving it alone beats guessing.
            default -> image;
        };
    }

    /** Clockwise, {@code times} quarter-turns. */
    private static BufferedImage quarterTurns(BufferedImage image, int times) {
        BufferedImage out = image;
        for (int i = 0; i < times; i++) {
            out = quarterTurn(out);
        }
        return out;
    }

    private static BufferedImage quarterTurn(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        // The canvas swaps dimensions: a portrait photo becomes landscape.
        BufferedImage out = new BufferedImage(height, width, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                out.setRGB(height - 1 - y, x, image.getRGB(x, y));
            }
        }
        return out;
    }

    private static BufferedImage flipHorizontally(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        BufferedImage out = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                out.setRGB(width - 1 - x, y, image.getRGB(x, y));
            }
        }
        return out;
    }

    /** Shrinks so the longer edge fits, keeping the aspect ratio. Never grows. */
    private static BufferedImage scaleWithin(BufferedImage image, int maxEdge) {
        int width = image.getWidth();
        int height = image.getHeight();
        int longest = Math.max(width, height);
        if (longest <= maxEdge) {
            return toOpaque(image);
        }

        double factor = (double) maxEdge / longest;
        int outWidth = Math.max(1, (int) Math.round(width * factor));
        int outHeight = Math.max(1, (int) Math.round(height * factor));

        BufferedImage out = new BufferedImage(outWidth, outHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
                RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.drawImage(image, 0, 0, outWidth, outHeight, null);
        g.dispose();
        return out;
    }

    /**
     * JPEG has no alpha channel. Writing an image that has one produces
     * inverted colours rather than an error, so a transparent PNG has to be
     * flattened before encoding.
     */
    private static BufferedImage toOpaque(BufferedImage image) {
        if (image.getType() == BufferedImage.TYPE_INT_RGB) {
            return image;
        }
        BufferedImage out = new BufferedImage(
                image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.drawImage(image, 0, 0, null);
        g.dispose();
        return out;
    }

    private static byte[] encodeJpeg(BufferedImage image) {
        ImageWriter writer = ImageIO.getImageWritersByFormatName("jpeg").next();
        ImageWriteParam params = writer.getDefaultWriteParam();
        params.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
        params.setCompressionQuality(JPEG_QUALITY);

        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (MemoryCacheImageOutputStream out = new MemoryCacheImageOutputStream(bytes)) {
            writer.setOutput(out);
            // Null metadata: nothing from the original comes through, which is
            // the whole point of this class.
            writer.write(null, new IIOImage(image, null, null), params);
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "Could not process that image. Please try again.");
        } finally {
            writer.dispose();
        }
        return bytes.toByteArray();
    }
}
