class Schedule < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :schedule_type, presence: true, inclusion: { in: %w[daily weekly] }
  
  has_many :schedule_medications, dependent: :destroy
  has_many :medications, through: :schedule_medications
  has_many :pillboxes, dependent: :destroy
  
  enum schedule_type: {
    daily: 'daily',
    weekly: 'weekly'
  }
  
  scope :active, -> { where(active: true) }
  
  def compartment_count
    case schedule_type
    when 'daily' then 4  # Morning, Afternoon, Evening, Bedtime
    when 'weekly' then 28 # 7 days * 4 times per day
    end
  end
end