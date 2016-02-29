require 'aws-sdk'

module FileUploader

  @@creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  @@s3 = Aws::S3::Resource.new(region: ENV['S3_REGION'], credentials: @@creds)
  BUCKET_NAME = ENV['S3_BUCKET']

  # S3 folder where all documents stored
  CAT_FOLDER  = ENV['CAT_FOLDER']

  def self.create_bucket_if_missing
    bucket = @@s3.bucket(BUCKET_NAME)
    unless bucket.exists?
      bucket.create({
        acl: "private", # accepts private, public-read, public-read-write, authenticated-read
      })
    end
  end

  def self.s3_key(file_name)
    "#{CAT_FOLDER}/#{file_name.to_s}"
  end

  def self.s3_obj(file_name)
    @@s3.bucket(BUCKET_NAME).
      object(file_name)
  end

  def self.upload_to_s3(file_location, file_name)
    bucket = @@s3.bucket(BUCKET_NAME)
    s3_file = bucket.object(self.s3_key(file_name))
    s3_file.upload_file(file_location) ? s3_file : nil
  end

  def self.get_public_url(s3_file, expiration_sec = 60)
    # create temporary pre-signed URL for downloads with expiration limit
    s3_file ? s3_file.presigned_url( :get, expires_in: expiration_sec ) : ""
  end

end
