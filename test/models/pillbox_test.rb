require_relative '../test_helper'

class PillboxTest < Minitest::Test
  def setup
    super
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end
  
  test "should create daily pillbox" do
    pillbox = @user.pillboxes.create!(
      name: 'Morning Meds',
      pillbox_type: 'daily'
    )
    
    assert pillbox.persisted?
    assert_equal 'Morning Meds', pillbox.name
    assert_equal 'daily', pillbox.pillbox_type
    assert pillbox.daily?
    refute pillbox.weekly?
  end
  
  test "should create weekly pillbox with auto-generated compartments" do
    pillbox = @user.pillboxes.create!(
      name: 'Weekly Organizer',
      pillbox_type: 'weekly'
    )
    
    assert_equal 7, pillbox.compartments.count
    
    days = pillbox.compartments.by_position.map(&:day_of_week)
    assert_equal ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'], days
  end
  
  test "should validate name presence" do
    pillbox = @user.pillboxes.build(
      pillbox_type: 'daily'
    )
    
    refute pillbox.valid?
    assert_includes pillbox.errors[:name], "can't be blank"
  end
  
  test "should validate name length" do
    pillbox = @user.pillboxes.build(
      name: 'a' * 16, # Exceeds 15 character limit
      pillbox_type: 'daily'
    )
    
    refute pillbox.valid?
    assert_includes pillbox.errors[:name], "is too long (maximum is 15 characters)"
  end
  
  test "should validate pillbox_type presence" do
    pillbox = @user.pillboxes.build(
      name: 'Test Box'
    )
    
    refute pillbox.valid?
    assert_includes pillbox.errors[:pillbox_type], "can't be blank"
  end
  
  test "should validate pillbox_type inclusion" do
    assert_raises ArgumentError do
      @user.pillboxes.create!(
        name: 'Test Box',
        pillbox_type: 'invalid_type'
      )
    end
  end
  
  test "should track last_filled_at timestamp" do
    pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'daily'
    )
    
    assert_nil pillbox.last_filled_at
    
    pillbox.update(last_filled_at: Time.current)
    
    assert_not_nil pillbox.last_filled_at
    assert_equal 0, pillbox.days_since_filled
  end
  
  test "should calculate days_since_filled" do
    pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'daily',
      last_filled_at: 3.days.ago
    )
    
    assert_equal 3, pillbox.days_since_filled
  end
  
  test "should determine needs_refill" do
    pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'weekly'
    )
    
    # Never filled
    assert pillbox.needs_refill?
    
    # Filled recently (within 7 days for weekly)
    pillbox.update(last_filled_at: 3.days.ago)
    refute pillbox.needs_refill?
    
    # Filled 8 days ago (needs refill)
    pillbox.update(last_filled_at: 8.days.ago)
    assert pillbox.needs_refill?
  end
  
  test "daily pillbox needs_refill threshold is 1 day" do
    pillbox = @user.pillboxes.create!(
      name: 'Daily Box',
      pillbox_type: 'daily'
    )
    
    # Same day - no refill needed
    pillbox.update(last_filled_at: Time.current)
    refute pillbox.needs_refill?
    
    # 2 days ago - needs refill
    pillbox.update(last_filled_at: 2.days.ago)
    assert pillbox.needs_refill?
  end
  
  test "should belong to user" do
    pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'daily'
    )
    
    assert_equal @user, pillbox.user
  end
  
  test "should have many compartments" do
    pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'daily'
    )
    
    pillbox.add_compartment(name: 'Morning')
    pillbox.add_compartment(name: 'Evening')
    
    assert_equal 2, pillbox.compartments.count
  end
  
  test "should destroy associated compartments when destroyed" do
    pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'daily'
    )
    
    pillbox.add_compartment(name: 'Morning')
    comp_id = pillbox.compartments.first.id
    
    pillbox.destroy
    
    assert_nil Compartment.find_by(id: comp_id)
  end
  
  test "should add compartments to daily pillbox" do
    pillbox = @user.pillboxes.create!(
      name: 'Daily Box',
      pillbox_type: 'daily'
    )
    
    comp = pillbox.add_compartment(name: 'Morning', time_of_day: 'morning')
    
    assert_equal 'Morning', comp.name
    assert_equal 'morning', comp.time_of_day
    assert_equal 1, comp.position
  end
  
  test "should enforce max compartments for daily pillbox" do
    pillbox = @user.pillboxes.create!(
      name: 'Daily Box',
      pillbox_type: 'daily'
    )
    
    # Add maximum allowed (12)
    12.times do |i|
      pillbox.add_compartment(name: "Compartment #{i + 1}")
    end
    
    assert_equal 12, pillbox.compartments.count
    
    # Try to add one more
    assert_raises RuntimeError do
      pillbox.add_compartment(name: 'Extra')
    end
  end
end
