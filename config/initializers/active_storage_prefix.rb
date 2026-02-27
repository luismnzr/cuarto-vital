# Prefix all Active Storage blob keys with a client-specific path so multiple
# studio instances can share a single S3 bucket without file collisions.
#
# Set STORAGE_PREFIX env var per client (e.g. "studio-alpha").
# Files will be stored under: s3://bucket/studio-alpha/<blob-key>
#
# If STORAGE_PREFIX is not set, blobs are stored at the bucket root (default behavior).

Rails.application.config.after_initialize do
  prefix = ENV["STORAGE_PREFIX"]

  if prefix.present? && defined?(ActiveStorage::Blob)
    ActiveStorage::Blob.prepend(Module.new do
      define_method(:key) do
        value = super()
        value.start_with?("#{prefix}/") ? value : "#{prefix}/#{value}"
      end
    end)
  end
end
