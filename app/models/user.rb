class User < ApplicationRecord
  # Since bcrypt should be loaded via Bundler.require, we just need has_secure_password
  has_secure_password
  
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
  before_save { self.email = email.downcase }
  
  # Associations with user's medical data
  has_many :medications, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_many :pillboxes, dependent: :destroy
  has_many :medication_logs, dependent: :destroy
  
  # Authentication helpers
  def self.authenticate(email, password)
    user = find_by(email: email.downcase)
    user && user.authenticate(password) ? user : nil
  end
  
  def full_name
    name
  end
  
  def initials
    name.split.map(&:first).join.upcase
  end
end