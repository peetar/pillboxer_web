class ScheduleMedication < ApplicationRecord
  belongs_to :schedule
  belongs_to :medication
  
  validates :time_of_day, presence: true, inclusion: { in: %w[morning afternoon evening bedtime] }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
end