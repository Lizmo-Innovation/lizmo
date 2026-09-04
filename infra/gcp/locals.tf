locals {
  # Built from the project ref rather than pasted, so recreating the Supabase
  # project means changing one value instead of finding every place the old
  # reference was written down.
  storage_endpoint = "https://${var.supabase_project_ref}.storage.supabase.co/storage/v1/s3"
}
