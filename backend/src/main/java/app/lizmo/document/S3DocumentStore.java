package app.lizmo.document;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.config.S3Properties;
import java.time.Duration;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

/**
 * The real store: a private S3 bucket, reached through presigned URLs.
 *
 * <p>Nothing here makes an object public. The bucket is private and stays that
 * way; every read goes through a URL that expires.
 */
@Component
public class S3DocumentStore implements DocumentStore {

    private final S3Client s3;
    private final S3Presigner presigner;
    private final S3Properties props;

    public S3DocumentStore(S3Client s3, S3Presigner presigner, S3Properties props) {
        this.s3 = s3;
        this.presigner = presigner;
        this.props = props;
    }

    @Override
    public void put(String key, byte[] bytes, String contentType) {
        try {
            s3.putObject(
                    PutObjectRequest.builder()
                            .bucket(props.bucket())
                            .key(key)
                            .contentType(contentType)
                            .build(),
                    RequestBody.fromBytes(bytes));
        } catch (S3Exception e) {
            // The tenant did nothing wrong, so this is ours, not a 400.
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "Could not store the file. Please try again.");
        }
    }

    @Override
    public String presignedUrl(String key, Duration validFor) {
        return presigner.presignGetObject(GetObjectPresignRequest.builder()
                        .signatureDuration(validFor)
                        .getObjectRequest(GetObjectRequest.builder()
                                .bucket(props.bucket())
                                .key(key)
                                .build())
                        .build())
                .url()
                .toString();
    }

    @Override
    public void delete(String key) {
        s3.deleteObject(DeleteObjectRequest.builder()
                .bucket(props.bucket())
                .key(key)
                .build());
    }
}
