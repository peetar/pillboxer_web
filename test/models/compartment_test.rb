require_relative '../test_helper'

class CompartmentTest < Minitest::Test
  def setup
    super
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    @pillbox = @user.pillboxes.create!(
      name: 'Test Box',
      pillbox_type: 'daily'
    )
  end
  
  test "should create compartment" do
    comp = @pillbox.add_compartment(name: 'Morning')
    
    assert comp.persisted?
    assert_equal 'Morning', comp.name
    assert_equal @pillbox, comp.pillbox
  end
  
  test "should validate name presence for daily pillbox" do
    comp = @pillbox.compartments.build
    
    refute comp.valid?
    assert_includes comp.errors[:name], "can't be blank"
  end
  
  test "should validate name length" do
    comp = @pillbox.compartments.build(
      name: 'a' * 11 # Exceeds 10 character limit
    )
    
    refute comp.valid?
    assert_includes comp.errors[:name], "is too long (maximum is 10 characters)"
  end
  
  test "should auto-increment position" do
    comp1 = @pillbox.add_compartment(name: 'Morning')
    comp2 = @pillbox.add_compartment(name: 'Noon')
    comp3 = @pillbox.add_compartment(name: 'Evening')
    
    assert_equal 1, comp1.position
    assert_equal 2, comp2.position
    assert_equal 3, comp3.position
  end
  
  test "should order by position" do
    comp3 = @pillbox.compartments.create!(name: 'Evening', position: 3)
    comp1 = @pillbox.compartments.create!(name: 'Morning', position: 1)
    comp2 = @pillbox.compartments.create!(name: 'Noon', position: 2)
    
    ordered = @pillbox.compartments.by_position
    
    assert_equal [comp1, comp2, comp3], ordered.to_a
  end
  
  test "should display name for daily compartment" do
    comp = @pillbox.add_compartment(name: 'Morning')
    
    assert_equal 'Morning', comp.display_name
  end
  
  test "should display capitalized day for weekly compartment" do
    weekly_box = @user.pillboxes.create!(
      name: 'Weekly',
      pillbox_type: 'weekly'
    )
    
    monday = weekly_box.compartments.find_by(day_of_week: 'monday')
    
    assert_equal 'Monday', monday.display_name
  end
  
  test "should add medication to compartment" do
    med = @user.medications.create!(
      name: 'Aspirin',
      dosage: '100mg',
      frequency: 'daily'
    )
    
    comp = @pillbox.add_compartment(name: 'Morning')
    comp.add_medication(med, quantity: 2)
    
    assert_equal 1, comp.compartment_medications.count
    assert_equal med, comp.compartment_medications.first.medication
    assert_equal 2, comp.compartment_medications.first.quantity
  end
  
  test "should have many compartment_medications" do
    comp = @pillbox.add_compartment(name: 'Morning')
    
    med1 = @user.medications.create!(name: 'Aspirin', dosage: '100mg', frequency: 'daily')
    med2 = @user.medications.create!(name: 'Vitamin D', dosage: '1000IU', frequency: 'daily')
    
    comp.add_medication(med1, quantity: 1)
    comp.add_medication(med2, quantity: 2)
    
    assert_equal 2, comp.compartment_medications.count
  end
  
  test "should have many medications through compartment_medications" do
    comp = @pillbox.add_compartment(name: 'Morning')
    
    med1 = @user.medications.create!(name: 'Aspirin', dosage: '100mg', frequency: 'daily')
    med2 = @user.medications.create!(name: 'Vitamin D', dosage: '1000IU', frequency: 'daily')
    
    comp.add_medication(med1, quantity: 1)
    comp.add_medication(med2, quantity: 2)
    
    assert_equal 2, comp.medications.count
    assert_includes comp.medications, med1
    assert_includes comp.medications, med2
  end
  
  test "should destroy associated compartment_medications when destroyed" do
    comp = @pillbox.add_compartment(name: 'Morning')
    med = @user.medications.create!(name: 'Aspirin', dosage: '100mg', frequency: 'daily')
    
    cm = comp.add_medication(med, quantity: 1)
    cm_id = cm.id
    
    comp.destroy
    
    assert_nil CompartmentMedication.find_by(id: cm_id)
  end
  
  test "should belong to pillbox" do
    comp = @pillbox.add_compartment(name: 'Morning')
    
    assert_equal @pillbox, comp.pillbox
  end
end
