class Registration < ActiveRecord::Base

  validates :poster_id, :status, :client_ip,
    :full_name, :email, :phone,
    presence: true

  has_many :payment_transactions
  belongs_to :poster

  INITIAL = 0
  REVIEW = 1
  PENDING = 2
  EXPIRED = 3
  REFUNDED = 4
  COMPLETED = 10
  FAILED = -1

end
