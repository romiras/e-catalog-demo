class Poster < ActiveRecord::Base

  validates :name, :sku, :price,
    presence: true

  validates :name, length: { in: 2..100 }

  validates :price,
    numericality: { greater_than_or_equal_to: 1.0 }

  has_one :document

end
