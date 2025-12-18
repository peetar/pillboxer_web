class CompartmentMedication < ApplicationRecord
  belongs_to :compartment
  belongs_to :medication
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
end