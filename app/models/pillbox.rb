class Pillbox < ApplicationRecord
  belongs_to :user
  belongs_to :schedule, optional: true
  
  validates :name, presence: true
  validates :pillbox_type, presence: true, inclusion: { in: %w[daily weekly] }
  validates :user, presence: true
  
  has_many :compartments, dependent: :destroy
  
  enum pillbox_type: {
    daily: 'daily',
    weekly: 'weekly'
  }
  
  after_create :create_default_compartments
  
  # Constants
  MAX_DAILY_COMPARTMENTS = 12
  DAYS_OF_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday].freeze
  
  # Scopes
  scope :by_type, ->(type) { where(pillbox_type: type) }
  scope :recently_filled, -> { where('last_filled_at > ?', 7.days.ago) }
  scope :needs_refill, -> { where('last_filled_at IS NULL OR last_filled_at < ?', 7.days.ago) }
  
  # Instance methods
  def filled?
    compartments.any?(&:filled?)
  end
  
  def total_medications
    compartments.sum(&:medication_count)
  end
  
  def mark_as_filled!(notes: nil)
    update!(last_filled_at: Time.current, notes: notes)
  end
  
  def days_since_filled
    return nil unless last_filled_at
    ((Time.current - last_filled_at) / 1.day).to_i
  end
  
  def needs_refill?
    last_filled_at.nil? || last_filled_at < 7.days.ago
  end
  
  def compartment_for(day: nil, time: nil)
    scope = compartments
    scope = scope.for_day(day) if day
    scope = scope.for_time(time) if time
    scope.first
  end
  
  def add_compartment(name:, time_of_day: nil)
    return false if daily? && compartments.count >= MAX_DAILY_COMPARTMENTS
    
    position = compartments.maximum(:position).to_i + 1
    compartments.create!(
      name: name,
      position: position,
      time_of_day: time_of_day
    )
  end
  
  private
  
  def create_default_compartments
    case pillbox_type
    when 'daily'
      # For daily pillboxes, don't auto-create compartments
      # Users will add them through the wizard (up to 12)
    when 'weekly'
      # Create 7 compartments, one for each day of the week
      DAYS_OF_WEEK.each_with_index do |day, index|
        compartments.create!(
          name: day.capitalize,
          position: index + 1,
          day_of_week: day
        )
      end
    end
  end
end