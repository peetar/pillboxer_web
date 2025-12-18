require_relative '../test_helper'

class CompartmentMedicationTest < Minitest::Test
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
    
    @compartment = @pillbox.add_compartment(name: 'Morning')
    
    @medication = @user.medications.create!(
      name: 'Aspirin',
      dosage: '100mg',
      frequency: 'daily'
    )
  end
  
  test "should create compartment medication" do
    cm = @compartment.add_medication(@medication, quantity: 2)
    
    assert cm.persisted?
    assert_equal @compartment, cm.compartment
    assert_equal @medication, cm.medication
    assert_equal 2, cm.quantity
  end
  
  test "should validate compartment presence" do
    cm = CompartmentMedication.new(
      medication: @medication,
      quantity: 1
    )
    
    refute cm.valid?
    assert_includes cm.errors[:compartment], "must exist"
  end
  
  test "should validate medication presence" do
    cm = CompartmentMedication.new(
      compartment: @compartment,
      quantity: 1
    )
    
    refute cm.valid?
    assert_includes cm.errors[:medication], "must exist"
  end
  
  test "should validate quantity presence" do
    cm = CompartmentMedication.new(
      compartment: @compartment,
      medication: @medication
    )
    
    refute cm.valid?
    assert_includes cm.errors[:quantity], "can't be blank"
  end
  
  test "should validate quantity is greater than zero" do
    cm = CompartmentMedication.new(
      compartment: @compartment,
      medication: @medication,
      quantity: 0
    )
    
    refute cm.valid?
    assert_includes cm.errors[:quantity], "must be greater than 0"
  end
  
  test "should validate quantity is numeric" do
    cm = CompartmentMedication.new(
      compartment: @compartment,
      medication: @medication,
      quantity: 'abc'
    )
    
    refute cm.valid?
    assert_includes cm.errors[:quantity], "is not a number"
  end
  
  test "should allow positive integer quantities" do
    cm = @compartment.add_medication(@medication, quantity: 5)
    
    assert cm.valid?
    assert_equal 5, cm.quantity
  end
  
  test "should belong to compartment" do
    cm = @compartment.add_medication(@medication, quantity: 1)
    
    assert_equal @compartment, cm.compartment
  end
  
  test "should belong to medication" do
    cm = @compartment.add_medication(@medication, quantity: 1)
    
    assert_equal @medication, cm.medication
  end
  
  test "should allow same medication in different compartments" do
    comp1 = @pillbox.add_compartment(name: 'Morning')
    comp2 = @pillbox.add_compartment(name: 'Evening')
    
    cm1 = comp1.add_medication(@medication, quantity: 1)
    cm2 = comp2.add_medication(@medication, quantity: 2)
    
    assert cm1.persisted?
    assert cm2.persisted?
    assert_equal 1, cm1.quantity
    assert_equal 2, cm2.quantity
  end
  
  test "should allow different medications in same compartment" do
    med1 = @user.medications.create!(name: 'Aspirin', dosage: '100mg', frequency: 'daily')
    med2 = @user.medications.create!(name: 'Vitamin D', dosage: '1000IU', frequency: 'daily')
    
    cm1 = @compartment.add_medication(med1, quantity: 1)
    cm2 = @compartment.add_medication(med2, quantity: 2)
    
    assert cm1.persisted?
    assert cm2.persisted?
    assert_equal 2, @compartment.compartment_medications.count
  end
end
