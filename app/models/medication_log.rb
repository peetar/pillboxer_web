class MedicationLog < ApplicationRecord
  belongs_to :user
  belongs_to :medication
  
  validates :taken_at, presence: true
  validates :scheduled_for, presence: true
  
  scope :taken, -> { where(taken: true) }
  scope :missed, -> { where(taken: false) }
  scope :today, -> { where(scheduled_for: Date.current.beginning_of_day..Date.current.end_of_day) }
end