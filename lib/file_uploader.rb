require 'aws-sdk'

module FileUploader

@@creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
@@s3 = Aws::S3::Resource.new(region: ENV['S3_REGION'], credentials: @@creds)

  def self.upload_to_s3(file_location, bucket_name, folder_name, file_name)
    bucket = @@s3.bucket(bucket_name)
    unless bucket.exists?
      bucket.create({
        acl: "private", # accepts private, public-read, public-read-write, authenticated-read
      })
    end
    key = "#{folder_name.to_s}/#{file_name.to_s}"
    s3_file = bucket.object(key)
    s3_file.upload_file(file_location)
    s3_file
  end

  def self.get_public_url(s3_file, expiration_sec = 60)
    # create temporary pre-signed URL for downloads with expiration limit
    s3_file.presigned_url( :get, expires_in: expiration_sec )
  end

end
