# Uploads do not live in Cloud Storage.
#
# There was a bucket here, and Terraform still provisions everything else the
# API needs -- but the API speaks S3, and Supabase Storage answers S3. Keeping
# the bucket meant either writing and proving a Cloud Storage client first, or
# leaving an empty bucket in the plan pretending to be part of the system.
#
# What replaced it: var.storage_endpoint and the two lizmo-storage-* secrets.
# If uploads ever move to Cloud Storage, this is the file to bring back, along
# with the object-admin binding that used to live in iam.tf.
