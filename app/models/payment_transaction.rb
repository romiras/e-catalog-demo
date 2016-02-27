class PaymentTransaction < ActiveRecord::Base

  validates :registration_id, :status, :gross_amount, :currency_code,
    presence: true
  
  serialize :notification_params, Hash

  before_create :generate_uuid

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end

end
