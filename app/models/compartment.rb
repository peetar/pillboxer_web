class Compartment < ApplicationRecord
  belongs_to :pillbox
  
  validates :name, presence: true
  validates :position, presence: true, uniqueness: { scope: :pillbox_id }
  validates :day_of_week, inclusion: { in: %w[monday tuesday wednesday thursday friday saturday sunday], allow_nil: true }
  
  has_many :compartment_medications, dependent: :destroy
  has_many :medications, through: :compartment_medications
  
  scope :by_position, -> { order(:position) }
  scope :for_day, ->(day) { where(day_of_week: day) }
  scope :for_time, ->(time) { where(time_of_day: time) }
  
  # Helper methods
  def filled?
    compartment_medications.any?
  end
  
  def medication_count
    compartment_medications.sum(:quantity)
  end
  
  def display_name
    if pillbox.daily?
      name
    elsif pillbox.weekly?
      day_of_week.capitalize
    else
      name
    end
  end
  
  def add_medication(medication, quantity: 1)
    compartment_medications.find_or_initialize_by(medication: medication).tap do |cm|
      cm.quantity = quantity
      cm.save!
    end
  end
  
  def remove_medication(medication)
    compartment_medications.find_by(medication: medication)&.destroy
  end
end