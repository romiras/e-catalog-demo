require 'file_uploader'

class Document < ActiveRecord::Base

  belongs_to :poster

  def public_url(expiration_time)
    s3_file = FileUploader.s3_obj(FileUploader.s3_key(self.filename))
    FileUploader.get_public_url(s3_file, expiration_time)
  end

  def self.downloadable_for?(registration)
    registration.purchased_at > 5.minutes.ago
  end

end

FileUploader.create_bucket_if_missing
