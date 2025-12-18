class Medication < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :dosage, presence: true
  validates :frequency, presence: true, inclusion: { in: %w[once_daily twice_daily three_times_daily four_times_daily as_needed] }
  
  has_many :schedule_medications, dependent: :destroy
  has_many :schedules, through: :schedule_medications
  has_many :medication_logs, dependent: :destroy
  
  enum frequency: {
    once_daily: 'once_daily',
    twice_daily: 'twice_daily', 
    three_times_daily: 'three_times_daily',
    four_times_daily: 'four_times_daily',
    as_needed: 'as_needed'
  }
  
  scope :active, -> { where(active: true) }
  
  def frequency_display
    frequency.humanize.gsub('_', ' ')
  end
  
  def times_per_day
    case frequency
    when 'once_daily' then 1
    when 'twice_daily' then 2
    when 'three_times_daily' then 3
    when 'four_times_daily' then 4
    else 0
    end
  end
end