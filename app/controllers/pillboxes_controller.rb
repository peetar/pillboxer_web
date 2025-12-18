class PillboxesController < ApplicationController
  before_action :require_login
  before_action :set_pillbox, only: [:show, :edit, :update, :destroy, :fill, :mark_filled]
  before_action :authorize_pillbox, only: [:show, :edit, :update, :destroy, :fill, :mark_filled]

  def index
    @pillboxes = current_user.pillboxes.includes(:compartments)
    render html: generate_index_html.html_safe
  end

  def show
    @compartments = @pillbox.compartments.by_position.includes(:compartment_medications, :medications)
    render html: generate_show_html.html_safe
  end

  def new
    # Redirect to wizard for new pill box creation
    redirect_to wizard_pillboxes_path
  end

  def wizard
    @pillbox = current_user.pillboxes.build
    @medications = current_user.medications.where(active: true)
    @step = params[:step]&.to_i || 1
    render html: generate_wizard_html.html_safe
  end

  def wizard_create
    pillbox_data = parse_wizard_data(params)
    
    # Validate required fields
    errors = []
    errors << "Pill box name is required" if pillbox_data[:name].blank?
    errors << "Pill box type is required" if pillbox_data[:type].blank?
    
    # Validate compartments for daily pill boxes
    if pillbox_data[:type] == 'daily'
      if pillbox_data[:compartments].empty?
        errors << "Daily pill boxes need at least one compartment"
      elsif pillbox_data[:compartments].count { |c| c.present? } > Pillbox::MAX_DAILY_COMPARTMENTS
        errors << "Daily pill boxes can have a maximum of #{Pillbox::MAX_DAILY_COMPARTMENTS} compartments"
      end
      
      # Check for duplicate compartment names
      non_blank = pillbox_data[:compartments].reject(&:blank?).map(&:strip)
      duplicates = non_blank.select { |name| non_blank.count(name) > 1 }.uniq
      if duplicates.any?
        errors << "Compartment names must be unique. Duplicates found: #{duplicates.join(', ')}"
      end
    end
    
    # Validate name length
    if pillbox_data[:name].present? && pillbox_data[:name].length > 15
      errors << "Pill box name is too long (maximum 15 characters)"
    end
    
    # Validate compartment name lengths for daily
    if pillbox_data[:type] == 'daily'
      long_compartments = pillbox_data[:compartments].reject(&:blank?).select { |name| name.strip.length > 10 }
      if long_compartments.any?
        errors << "Compartment names are too long (maximum 10 characters)"
      end
    end
    
    if errors.any?
      @medications = current_user.medications.where(active: true)
      @step = 1
      render html: generate_wizard_html(errors: errors).html_safe, status: :unprocessable_entity
      return
    end
    
    @pillbox = current_user.pillboxes.build(
      name: pillbox_data[:name],
      pillbox_type: pillbox_data[:type],
      notes: pillbox_data[:notes]
    )
    
    if @pillbox.save
      # Add compartments based on type
      if @pillbox.daily?
        # For daily: use compartment names from form
        pillbox_data[:compartments].each_with_index do |comp_name, index|
          next if comp_name.blank?
          @pillbox.compartments.create!(
            name: comp_name.strip,
            position: index + 1,
            time_of_day: comp_name.strip.downcase.gsub(/\s+/, '_')
          )
        end
      end
      # Weekly compartments are auto-created by after_create callback in model
      
      # Add medications to compartments if assignments provided
      if pillbox_data[:medication_assignments].present?
        @pillbox.compartments.reload # Ensure we have the compartments
        
        pillbox_data[:medication_assignments].each do |assignment_key, med_data|
          # assignment_key could be compartment name or day of week
          # Find compartment by name for daily, by day_of_week for weekly
          compartment = if @pillbox.daily?
            @pillbox.compartments.find_by(name: assignment_key) || 
            @pillbox.compartments.offset(assignment_key.to_i).first
          else
            @pillbox.compartments.find_by(day_of_week: assignment_key)
          end
          
          next unless compartment
          
          # med_data is now a hash of med_id => quantity
          med_data.each do |med_id, quantity|
            next if med_id.blank? || quantity.blank? || quantity.to_i <= 0
            medication = current_user.medications.find_by(id: med_id)
            next unless medication
            
            compartment.add_medication(medication, quantity: quantity.to_i)
          end
        end
      end
      
      redirect_to pillbox_path(@pillbox)
    else
      @medications = current_user.medications.where(active: true)
      @step = 1
      render html: generate_wizard_html(errors: @pillbox.errors.full_messages).html_safe, status: :unprocessable_entity
    end
  end

  def create
    @pillbox = current_user.pillboxes.build(pillbox_params)
    
    if @pillbox.save
      redirect_to pillbox_path(@pillbox), notice: 'Pill box created successfully!'
    else
      render html: generate_new_html(errors: @pillbox.errors.full_messages).html_safe, status: :unprocessable_entity
    end
  end

  def edit
    @medications = current_user.medications.where(active: true)
    @compartments = @pillbox.compartments.by_position.includes(:compartment_medications, :medications)
    render html: generate_edit_html.html_safe
  end

  def update
    if @pillbox.update(pillbox_params)
      # Update medication assignments
      if params[:medication_assignments].present?
        params[:medication_assignments].each do |comp_id, assignments|
          compartment = @pillbox.compartments.find_by(id: comp_id)
          next unless compartment
          
          # Clear existing assignments for this compartment
          compartment.compartment_medications.destroy_all
          
          # Add new assignments
          if assignments[:medications].present?
            assignments[:medications].each do |med_id, quantity_data|
              next if med_id.blank? || quantity_data[:quantity].to_i <= 0
              
              compartment.compartment_medications.create(
                medication_id: med_id,
                quantity: quantity_data[:quantity].to_i
              )
            end
          end
        end
      end
      
      redirect_to pillbox_path(@pillbox), notice: 'Pill box updated successfully!'
    else
      @medications = current_user.medications.where(active: true)
      @compartments = @pillbox.compartments.by_position.includes(:compartment_medications, :medications)
      render html: generate_edit_html(errors: @pillbox.errors.full_messages).html_safe, status: :unprocessable_entity
    end
  end

  def destroy
    @pillbox.destroy
    redirect_to root_path, notice: 'Pill box deleted successfully!'
  end

  # Fill wizard actions
  def fill
    @compartments = @pillbox.compartments.order(:position)
    render html: generate_fill_html.html_safe
  end

  def mark_filled
    # Update last_filled_at timestamp
    @pillbox.update(last_filled_at: Time.current)
    
    redirect_to pillbox_path(@pillbox), notice: "Pill box marked as filled!"
  end

  private

  def set_pillbox
    @pillbox = Pillbox.find(params[:id])
  end

  def authorize_pillbox
    unless @pillbox.user_id == current_user.id
      redirect_to root_path, alert: 'You are not authorized to access this pill box.'
    end
  end

  def pillbox_params
    params.require(:pillbox).permit(:name, :pillbox_type, :notes)
  end

  def parse_wizard_data(params)
    {
      name: params[:pillbox_name],
      type: params[:pillbox_type],
      notes: params[:pillbox_notes],
      compartments: params[:compartments] || [],
      medication_assignments: params[:medication_assignments] || {}
    }
  end

  def generate_wizard_html(errors: [])
    user = current_user
    medications = @medications
    
    <<~HTML
      #{render_header(user, 'Create Pill Box - Wizard')}
      <link rel="stylesheet" href="/assets/wizard.css">
      
      <div class="wizard-container" style="max-width: 900px; margin: 0 auto; padding: 40px 20px;">
        <div style="margin-bottom: 20px;">
          <a href="/" style="color: #3b82f6; text-decoration: none;">← Back to Dashboard</a>
        </div>

        #{render_boxxy_greeting}

        <form action="/pillboxes/wizard" method="post" data-controller="wizard" data-wizard-total-steps-value="4" data-wizard-current-step-value="1">
          <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
          <input type="hidden" name="_method" value="post">

          #{render_wizard_progress_bar}

          #{if errors.any?
            "<div style=\"background: #fee2e2; border-left: 4px solid #ef4444; padding: 16px; border-radius: 6px; margin-bottom: 20px;\">
              <strong style=\"color: #991b1b;\">Please fix the following errors:</strong>
              <ul style=\"margin: 10px 0 0 20px; color: #991b1b;\">
                #{errors.map { |error| "<li>#{error}</li>" }.join('')}
              </ul>
            </div>"
          else
            ""
          end}

          <!-- Step 1: Choose Type -->
          #{render_step_1}

          <!-- Step 2: Configure Compartments -->
          #{render_step_2}

          <!-- Step 3: Assign Medications -->
          #{render_step_3(medications)}

          <!-- Step 4: Review -->
          #{render_step_4}

      #{render_wizard_navigation_buttons}
        </form>
      </div>
      
      <script>
        // Initialize everything when DOM is ready
        document.addEventListener('DOMContentLoaded', () => {
          
          // Wizard controller functionality
          class WizardManager {
            constructor(form) {
              this.form = form;
              this.currentStep = 1;
              this.totalSteps = 4;
              this.steps = form.querySelectorAll('[data-wizard-target="step"]');
              this.nextBtn = form.querySelector('[data-wizard-target="nextBtn"]');
              this.prevBtn = form.querySelector('[data-wizard-target="prevBtn"]');
              this.submitBtn = form.querySelector('[data-wizard-target="submitBtn"]');
              this.progressBar = form.querySelector('[data-wizard-target="progress"]');
              
              this.init();
            }
            
            init() {
              // Attach event listeners
              if (this.nextBtn) {
                this.nextBtn.addEventListener('click', (e) => {
                  e.preventDefault();
                  this.next();
                });
              }
              
              if (this.prevBtn) {
                this.prevBtn.addEventListener('click', (e) => {
                  e.preventDefault();
                  this.previous();
                });
              }
              
              this.showStep(1);
            }
            
            next() {
              if (this.validateCurrentStep() && this.currentStep < this.totalSteps) {
                this.currentStep++;
                this.showStep(this.currentStep);
              }
            }
            
            previous() {
              if (this.currentStep > 1) {
                this.currentStep--;
                this.showStep(this.currentStep);
              }
            }
            
            showStep(stepNum) {
              console.log('showStep called for step', stepNum, '- have', this.steps.length, 'steps');
              
              // Hide all steps
              this.steps.forEach((step, index) => {
                const shouldShow = index + 1 === stepNum;
                step.style.display = shouldShow ? 'block' : 'none';
                if (shouldShow) {
                  console.log('Showing step', stepNum, '- element:', step.tagName, step.className);
                }
              });
              
              this.updateProgress();
              this.updateButtons();
              window.scrollTo({ top: 0, behavior: 'smooth' });
              
              // Trigger step-specific logic
              if (stepNum === 3) {
                setTimeout(() => populateMedicationAssignments(), 100);
              } else if (stepNum === 4) {
                setTimeout(() => updateReviewSummary(), 100);
              }
            }
            
            updateProgress() {
              const percentage = (this.currentStep / this.totalSteps) * 100;
              if (this.progressBar) {
                this.progressBar.style.width = percentage + '%';
              }
              
              // Update step indicators
              const indicators = document.querySelectorAll('.step-indicator');
              indicators.forEach((indicator, index) => {
                const circle = indicator.querySelector('div');
                const label = indicator.querySelector('div:last-child');
                const stepNum = index + 1;
                
                if (stepNum === this.currentStep) {
                  circle.style.borderColor = '#3b82f6';
                  circle.style.background = '#3b82f6';
                  circle.style.color = 'white';
                  label.style.color = '#1f2937';
                  label.style.fontWeight = '600';
                } else if (stepNum < this.currentStep) {
                  circle.style.borderColor = '#10b981';
                  circle.style.background = '#10b981';
                  circle.style.color = 'white';
                  label.style.color = '#6b7280';
                  label.style.fontWeight = '400';
                } else {
                  circle.style.borderColor = '#d1d5db';
                  circle.style.background = 'white';
                  circle.style.color = '#9ca3af';
                  label.style.color = '#6b7280';
                  label.style.fontWeight = '400';
                }
              });
            }
            
            updateButtons() {
              if (this.prevBtn) {
                this.prevBtn.style.display = this.currentStep === 1 ? 'none' : 'block';
              }
              
              if (this.nextBtn && this.submitBtn) {
                if (this.currentStep === this.totalSteps) {
                  this.nextBtn.style.display = 'none';
                  this.submitBtn.style.display = 'block';
                } else {
                  this.nextBtn.style.display = 'block';
                  this.submitBtn.style.display = 'none';
                }
              }
            }
            
            validateCurrentStep() {
              const currentStepEl = this.steps[this.currentStep - 1];
              const requiredInputs = currentStepEl.querySelectorAll('[required]');
              let isValid = true;
              let errorMessages = [];
              const radioGroups = {};
              
              requiredInputs.forEach(input => {
                if (input.type === 'radio') {
                  if (!radioGroups[input.name]) {
                    radioGroups[input.name] = currentStepEl.querySelectorAll('input[name="' + input.name + '"]');
                  }
                } else if (!input.value || input.value.trim() === '') {
                  isValid = false;
                  input.style.borderColor = '#ef4444';
                  input.addEventListener('input', () => {
                    input.style.borderColor = '';
                  }, { once: true });
                }
              });
              
              // Check radio groups
              Object.values(radioGroups).forEach(group => {
                const hasChecked = Array.from(group).some(radio => radio.checked);
                if (!hasChecked) {
                  isValid = false;
                  errorMessages.push('Please select an option');
                }
              });
              
              // Step 2 specific validation: Check compartments for daily type
              if (this.currentStep === 2) {
                const selectedType = document.querySelector('input[name="pillbox_type"]:checked')?.value;
                if (selectedType === 'daily') {
                  const compartmentInputs = currentStepEl.querySelectorAll('input[name^="compartments"]');
                  const filledCompartments = Array.from(compartmentInputs).filter(input => input.value.trim() !== '');
                  
                  if (filledCompartments.length === 0) {
                    isValid = false;
                    errorMessages.push('Please add at least one compartment');
                  } else if (filledCompartments.length > 12) {
                    isValid = false;
                    errorMessages.push('Maximum 12 compartments allowed');
                  }
                  
                  // Check for duplicate names
                  const names = filledCompartments.map(input => input.value.trim().toLowerCase());
                  const duplicates = names.filter((name, index) => names.indexOf(name) !== index);
                  if (duplicates.length > 0) {
                    isValid = false;
                    errorMessages.push('Compartment names must be unique');
                  }
                }
              }
              
              if (!isValid) {
                const message = errorMessages.length > 0 ? errorMessages.join('\\n') : 'Please fill in all required fields';
                alert(message);
              }
              
              return isValid;
            }
          }
          
          // Initialize wizard
          const wizardForm = document.querySelector('[data-controller="wizard"]');
          if (wizardForm) {
            window.wizardManager = new WizardManager(wizardForm);
            
            // Debug: Check what steps we have
            const allSteps = wizardForm.querySelectorAll('[data-wizard-target="step"]');
            console.log('DEBUG: Found', allSteps.length, 'steps in total');
            allSteps.forEach((step, idx) => {
              console.log('Step', idx + 1, '- data-step:', step.getAttribute('data-step'), '- display:', step.style.display);
            });
          }
          
          let compartmentCounter = 0;
          const MAX_COMPARTMENTS = 12;

          // Type selection handler
          const typeRadios = document.querySelectorAll('input[name="pillbox_type"]');
          typeRadios.forEach(radio => {
            radio.addEventListener('change', (e) => {
              // Highlight selected card
              document.querySelectorAll('.pillbox-type-card').forEach(card => {
                card.classList.remove('selected');
              });
              e.target.closest('.pillbox-type-card').classList.add('selected');
              
              // Show appropriate compartment section in step 2
              const type = e.target.value;
              if (type === 'daily') {
                document.getElementById('daily-compartments').style.display = 'block';
                document.getElementById('weekly-compartments').style.display = 'none';
              } else {
                document.getElementById('daily-compartments').style.display = 'none';
                document.getElementById('weekly-compartments').style.display = 'block';
              }
            });
          });

          // Compartment management for daily pill boxes
          const addCompartmentBtn = document.getElementById('add-compartment-btn');
          const compartmentList = document.getElementById('compartment-list');
          const compartmentCount = document.getElementById('compartment-count');

          if (addCompartmentBtn) {
            addCompartmentBtn.addEventListener('click', () => {
              if (compartmentCounter >= MAX_COMPARTMENTS) {
                alert('Maximum of 12 compartments reached');
                return;
              }

              compartmentCounter++;
              const compartmentDiv = document.createElement('div');
              compartmentDiv.style.cssText = 'display: flex; gap: 12px; margin-bottom: 12px; align-items: center;';
              compartmentDiv.innerHTML = `
                <input type="text" 
                       name="compartments[]" 
                       required 
                       maxlength="10"
                       placeholder="e.g., Morning"
                       style="flex: 1; padding: 10px; border: 2px solid #d1d5db; border-radius: 6px;">
                <button type="button" onclick="this.parentElement.remove(); updateCompartmentCount();" 
                        style="background: #ef4444; color: white; padding: 10px 16px; border: none; border-radius: 6px; cursor: pointer;">
                  Remove
                </button>
              `;
              compartmentList.appendChild(compartmentDiv);
              updateCompartmentCount();

              if (compartmentCounter >= MAX_COMPARTMENTS) {
                addCompartmentBtn.disabled = true;
                addCompartmentBtn.style.opacity = '0.5';
                addCompartmentBtn.style.cursor = 'not-allowed';
              }
            });
          }

          window.updateCompartmentCount = () => {
            const count = document.querySelectorAll('input[name="compartments[]"]').length;
            compartmentCounter = count;
            compartmentCount.textContent = count;
            
            if (count < MAX_COMPARTMENTS && addCompartmentBtn) {
              addCompartmentBtn.disabled = false;
              addCompartmentBtn.style.opacity = '1';
              addCompartmentBtn.style.cursor = 'pointer';
            }
          };

          // Populate medication assignments in step 3 based on compartments
          function populateMedicationAssignments() {
            console.log('populateMedicationAssignments called');
            const type = document.querySelector('input[name="pillbox_type"]:checked')?.value;
            const container = document.getElementById('compartment-medication-assignments');
            
            console.log('Type:', type, 'Container found:', !!container);
            
            if (!container || !type) return;

            const medications = #{medications.map { |m| { id: m.id, name: m.name } }.to_json};
            
            console.log('Medications:', medications.length);
            
            if (medications.length === 0) return;

            let compartments = [];
            if (type === 'daily') {
              const inputs = Array.from(document.querySelectorAll('input[name="compartments[]"]'));
              compartments = inputs.map((input, index) => ({
                key: input.value,
                label: input.value || `Compartment ${index + 1}`
              })).filter(c => c.key);
            } else {
              compartments = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map(day => ({
                key: day.toLowerCase(),
                label: day
              }));
            }

            console.log('Compartments to show:', compartments.length);

            if (compartments.length === 0) {
              container.innerHTML = '<p style="color: #6b7280; font-style: italic;">Please add at least one compartment in Step 2.</p>';
              return;
            }

            container.innerHTML = compartments.map(comp => `
              <div style="background: white; border: 2px solid #d1d5db; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
                <h4 style="margin: 0 0 12px 0; color: #1f2937; font-size: 16px; font-weight: 600;">
                  ${comp.label}
                </h4>
                <div style="display: grid; gap: 8px;">
                  ${medications.map(med => `
                    <label style="display: flex; align-items: center; padding: 8px; border-radius: 6px; cursor: pointer; transition: background 0.2s;" onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                      <input type="checkbox" 
                             class="wizard-med-checkbox"
                             data-comp="${comp.key}"
                             data-med="${med.id}"
                             onchange="const qtyInput = this.parentElement.querySelector('.wizard-qty-input'); qtyInput.disabled = !this.checked; if (this.checked && !qtyInput.value) qtyInput.value = '1'; else if (!this.checked) qtyInput.value = '';"
                             style="width: 18px; height: 18px; margin-right: 12px;">
                      <span style="color: #374151; font-size: 14px; flex: 1;">${med.name}</span>
                      <div style="display: flex; align-items: center; gap: 6px; margin-left: 12px;">
                        <span style="color: #6b7280; font-size: 13px; font-weight: 500;">Qty:</span>
                        <input type="number"
                               class="wizard-qty-input"
                               name="medication_assignments[${comp.key}][${med.id}]"
                               min="1"
                               max="99"
                               disabled
                               placeholder="0"
                               style="width: 60px; padding: 4px 8px; border: 2px solid #d1d5db; border-radius: 4px; text-align: center; font-size: 13px; font-weight: 600;">
                      </div>
                    </label>
                  `).join('')}
                </div>
              </div>
            `).join('');
            
            console.log('Step 3 populated with medication assignments');
          }

          // Update review summary when moving to step 4
          function updateReviewSummary() {
            const name = document.querySelector('input[name="pillbox_name"]')?.value || '—';
            const type = document.querySelector('input[name="pillbox_type"]:checked')?.value || '—';
            const notes = document.querySelector('textarea[name="pillbox_notes"]')?.value;

            document.getElementById('review-name').textContent = name;
            document.getElementById('review-type').textContent = type === 'daily' ? '📅 Daily' : '📆 Weekly';

            if (type === 'daily') {
              const compartments = Array.from(document.querySelectorAll('input[name="compartments[]"]')).map(input => input.value);
              document.getElementById('review-compartments').innerHTML = compartments.length > 0
                ? compartments.map(c => `<span style="display: inline-block; background: #eff6ff; padding: 4px 12px; border-radius: 6px; margin: 4px 4px 4px 0; color: #1e40af;">${c}</span>`).join('')
                : '<em style="color: #6b7280;">No compartments added</em>';
            } else {
              document.getElementById('review-compartments').textContent = '7 daily compartments (Monday-Sunday)';
            }

            if (notes) {
              document.getElementById('review-notes-section').style.display = 'block';
              document.getElementById('review-notes').textContent = notes;
            } else {
              document.getElementById('review-notes-section').style.display = 'none';
            }

            // Show medication assignments with quantities
            const medications = #{medications.map { |m| { id: m.id.to_s, name: m.name } }.to_json};
            const checkedCheckboxes = document.querySelectorAll('.wizard-med-checkbox:checked');
            
            if (checkedCheckboxes.length > 0) {
              const assignmentsByComp = {};
              checkedCheckboxes.forEach(checkbox => {
                const compKey = checkbox.dataset.comp;
                const medId = checkbox.dataset.med;
                const qtyInput = checkbox.parentElement.querySelector('.wizard-qty-input');
                const quantity = qtyInput ? qtyInput.value : '1';
                
                if (!assignmentsByComp[compKey]) assignmentsByComp[compKey] = [];
                const med = medications.find(m => m.id === medId);
                if (med) {
                  assignmentsByComp[compKey].push({ name: med.name, qty: quantity || '1' });
                }
              });

              const assignmentHtml = Object.entries(assignmentsByComp).map(([comp, meds]) => `
                <div style="margin-bottom: 12px;">
                  <strong style="color: #1f2937; display: block; margin-bottom: 4px;">${comp}:</strong>
                  <div style="margin-left: 16px;">
                    ${meds.map(m => `<div style="color: #6b7280; font-size: 13px;">• ${m.name} <span style="background: #3b82f6; color: white; padding: 2px 6px; border-radius: 10px; font-size: 11px; font-weight: 600; margin-left: 4px;">× ${m.qty}</span></div>`).join('')}
                  </div>
                </div>
              `).join('');

              document.getElementById('review-medications').innerHTML = assignmentHtml;
            } else {
              document.getElementById('review-medications').innerHTML = '<em style="color: #6b7280;">No medications assigned</em>';
            }
          }
        });
      </script>
      #{render_footer}
    HTML
  end

  def render_boxxy_greeting
    <<~HTML
      <div style="text-align: center; margin: 30px 0;">
        <img src="/assets/boxxy.svg" alt="Boxxy" style="width: 150px; height: 150px; margin-bottom: 10px;">
        <div style="background: white; border: 3px solid #3b82f6; border-radius: 20px; padding: 16px 24px; display: inline-block; box-shadow: 0 4px 12px rgba(0,0,0,0.15); max-width: 500px; position: relative; margin-top: -10px;">
          <div style="position: absolute; top: -12px; left: 50%; transform: translateX(-50%); width: 0; height: 0; border-left: 12px solid transparent; border-right: 12px solid transparent; border-bottom: 12px solid #3b82f6;"></div>
          <p style="margin: 0; color: #1f2937; font-size: 16px; font-weight: 500;">
            Woof! 🐕 I'm Boxxy, and I'll help you set up your pill box! Let's get started!
          </p>
        </div>
      </div>
    HTML
  end

  def render_wizard_progress_bar
    <<~HTML
      <div style="margin: 40px 0;">
        <div style="background: #e5e7eb; height: 8px; border-radius: 10px; overflow: hidden; margin-bottom: 20px;">
          <div data-wizard-target="progress" 
               style="background: linear-gradient(90deg, #3b82f6 0%, #2563eb 100%); height: 100%; width: 25%; transition: width 0.4s ease;"
               role="progressbar" 
               aria-valuenow="25" 
               aria-valuemin="0" 
               aria-valuemax="100">
          </div>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; gap: 8px;">
          #{['Choose Type', 'Setup Compartments', 'Add Medications', 'Review'].map.with_index { |label, index|
            step_num = index + 1
            <<~STEP
              <div class="step-indicator #{step_num == 1 ? 'active' : ''}" style="flex: 1; text-align: center;">
                <div style="width: 40px; height: 40px; border-radius: 50%; border: 3px solid #{step_num == 1 ? '#3b82f6' : '#d1d5db'}; display: inline-flex; align-items: center; justify-content: center; font-weight: 700; margin-bottom: 8px; background: #{step_num == 1 ? '#3b82f6' : 'white'}; color: #{step_num == 1 ? 'white' : '#9ca3af'};">
                  #{step_num}
                </div>
                <div style="font-size: 12px; color: #{step_num == 1 ? '#1f2937' : '#6b7280'}; font-weight: #{step_num == 1 ? '600' : '400'};">
                  #{label}
                </div>
              </div>
            STEP
          }.join('')}
        </div>
      </div>
    HTML
  end

  def render_step_1
    <<~HTML
      <div data-wizard-target="step" data-step="1" class="wizard-step" style="display: block;">
        <h2 style="margin: 0 0 10px 0; font-size: 24px; color: #1f2937;">Step 1: Choose Your Pill Box Type</h2>
        <p style="color: #6b7280; margin: 0 0 30px 0;">Select the type that matches your physical pill box</p>

        <div style="display: grid; gap: 16px; margin: 20px 0;">
          <label class="pillbox-type-card" style="display: flex; align-items: start; padding: 20px; border: 2px solid #d1d5db; border-radius: 12px; cursor: pointer; transition: all 0.2s;">
            <input type="radio" name="pillbox_type" value="daily" required style="margin-top: 4px; margin-right: 16px; width: 20px; height: 20px;" data-action="change->wizard#selectPillboxType">
            <div style="flex: 1;">
              <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
                <span style="font-size: 32px;">📅</span>
                <strong style="font-size: 18px; color: #1f2937;">Daily Pill Box</strong>
              </div>
              <p style="color: #6b7280; font-size: 14px; margin: 0 0 12px 0;">
                Perfect for organizing medications by time of day. You can set up to 12 compartments for different times (e.g., Morning, Noon, Evening, Bedtime).
              </p>
              <div style="background: #eff6ff; padding: 12px; border-radius: 6px; border-left: 3px solid #3b82f6;">
                <p style="margin: 0; font-size: 13px; color: #1e40af;">
                  ✓ Up to 12 custom time slots<br>
                  ✓ Great for multiple medications throughout the day<br>
                  ✓ Flexible compartment naming
                </p>
              </div>
            </div>
          </label>

          <label class="pillbox-type-card" style="display: flex; align-items: start; padding: 20px; border: 2px solid #d1d5db; border-radius: 12px; cursor: pointer; transition: all 0.2s;">
            <input type="radio" name="pillbox_type" value="weekly" required style="margin-top: 4px; margin-right: 16px; width: 20px; height: 20px;" data-action="change->wizard#selectPillboxType">
            <div style="flex: 1;">
              <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
                <span style="font-size: 32px;">📆</span>
                <strong style="font-size: 18px; color: #1f2937;">Weekly Pill Box</strong>
              </div>
              <p style="color: #6b7280; font-size: 14px; margin: 0 0 12px 0;">
                Ideal for weekly medication organizers with one compartment per day. Automatically creates 7 compartments labeled Monday through Sunday.
              </p>
              <div style="background: #f0fdf4; padding: 12px; border-radius: 6px; border-left: 3px solid #10b981;">
                <p style="margin: 0; font-size: 13px; color: #065f46;">
                  ✓ 7 compartments (one per day)<br>
                  ✓ Simple weekly organization<br>
                  ✓ Perfect for once-daily medications
                </p>
              </div>
            </div>
          </label>
        </div>

        <div style="margin-top: 30px;">
          <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Pill Box Name *</label>
          <input type="text" name="pillbox_name" required maxlength="15"
                 style="width: 100%; padding: 12px; border: 2px solid #d1d5db; border-radius: 8px; font-size: 16px;" 
                 placeholder="e.g., My Morning Meds, Weekly Organizer">
          <p style="color: #6b7280; font-size: 13px; margin: 6px 0 0 0;">Give your pill box a memorable name (max 15 characters)</p>
        </div>
      </div>
    HTML
  end

  def render_step_2
    <<~HTML
      <div data-wizard-target="step" data-step="2" class="wizard-step" style="display: none;">
        <h2 style="margin: 0 0 10px 0; font-size: 24px; color: #1f2937;">Step 2: Configure Compartments</h2>
        <p style="color: #6b7280; margin: 0 0 30px 0;">Set up the compartments for your pill box</p>

        <div id="daily-compartments" style="display: none;">
          <div style="background: #eff6ff; padding: 16px; border-radius: 8px; border-left: 4px solid #3b82f6; margin-bottom: 20px;">
            <p style="margin: 0; color: #1e40af; font-size: 14px;">
              📅 <strong>Daily Pill Box:</strong> Add up to 12 time-based compartments (e.g., Morning, Noon, Evening). Max 10 characters each.
            </p>
          </div>

          <div id="compartment-list" style="margin-bottom: 20px;">
            <!-- Compartments will be added here dynamically -->
          </div>

          <button type="button" id="add-compartment-btn" 
                  style="background: #10b981; color: white; padding: 10px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: 600;">
            + Add Compartment
          </button>
          <p style="color: #6b7280; font-size: 13px; margin: 8px 0 0 0;">
            <span id="compartment-count">0</span> of 12 compartments added
          </p>
        </div>

        <div id="weekly-compartments" style="display: none;">
          <div style="background: #f0fdf4; padding: 16px; border-radius: 8px; border-left: 4px solid #10b981; margin-bottom: 20px;">
            <p style="margin: 0; color: #065f46; font-size: 14px;">
              📆 <strong>Weekly Pill Box:</strong> Seven compartments are created, one for each day of the week (Monday-Sunday)
            </p>
          </div>

          <div style="background: white; border: 2px solid #d1d5db; border-radius: 8px; padding: 20px;">
            <h3 style="margin: 0 0 16px 0; color: #374151; font-size: 16px;">Preview of compartments:</h3>
            <div style="display: grid; gap: 12px;">
              #{['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map { |day|
                "<div style=\"padding: 12px; background: #f9fafb; border-radius: 6px; border-left: 3px solid #10b981;\">
                  <strong style=\"color: #1f2937;\">#{day}</strong>
                </div>"
              }.join('')}
            </div>
          </div>
        </div>

        <div style="margin-top: 30px;">
          <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Notes (Optional)</label>
          <textarea name="pillbox_notes" rows="3"
                    style="width: 100%; padding: 12px; border: 2px solid #d1d5db; border-radius: 8px; font-size: 14px; font-family: inherit;" 
                    placeholder="Add any notes about this pill box..."></textarea>
        </div>
      </div>
    HTML
  end

  def render_step_3(medications)
    <<~HTML
      <div data-wizard-target="step" data-step="3" class="wizard-step" style="display: none;">
        <h2 style="margin: 0 0 10px 0; font-size: 24px; color: #1f2937;">Step 3: Assign Medications</h2>
        <p style="color: #6b7280; margin: 0 0 30px 0;">Select which medications belong in each compartment</p>

        <div id="medication-assignment-container">
          #{if medications.any?
            "<div style=\"background: #fef3c7; padding: 16px; border-radius: 8px; border-left: 4px solid #f59e0b; margin-bottom: 20px;\">
              <p style=\"margin: 0; color: #92400e; font-size: 14px;\">
                💊 Select medications for each compartment. You can assign the same medication to multiple compartments.
              </p>
            </div>

            <div id=\"compartment-medication-assignments\">
              <!-- Will be populated based on compartments from step 2 -->
              <p style=\"color: #6b7280; font-style: italic;\">Complete step 2 first to see compartment options here.</p>
            </div>"
          else
            "<div style=\"background: #fee2e2; padding: 20px; border-radius: 8px; border-left: 4px solid #ef4444; text-align: center;\">
              <p style=\"margin: 0 0 12px 0; color: #991b1b; font-weight: 600;\">No Active Medications</p>
              <p style=\"margin: 0; color: #991b1b; font-size: 14px;\">
                You need to add medications first before you can assign them to pill box compartments.
              </p>
              <a href=\"/medications/new\" style=\"display: inline-block; margin-top: 16px; background: #ef4444; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-weight: 600;\">
                + Add Your First Medication
              </a>
            </div>"
          end}
        </div>
      </div>
    HTML
  end

  def render_step_4
    <<~HTML
      <div data-wizard-target="step" data-step="4" class="wizard-step" style="display: none;">
        <h2 style="margin: 0 0 10px 0; font-size: 24px; color: #1f2937;">Step 4: Review & Create</h2>
        <p style="color: #6b7280; margin: 0 0 30px 0;">Review your pill box setup before creating it</p>

        <div style="background: white; border: 2px solid #d1d5db; border-radius: 12px; padding: 24px;">
          <h3 style="margin: 0 0 20px 0; color: #374151; font-size: 18px; border-bottom: 2px solid #e5e7eb; padding-bottom: 12px;">Summary</h3>

          <div id="review-summary" style="display: grid; gap: 16px;">
            <div>
              <label style="display: block; font-weight: 600; color: #6b7280; font-size: 13px; margin-bottom: 4px;">PILL BOX NAME</label>
              <div id="review-name" style="color: #1f2937; font-size: 16px;">—</div>
            </div>

            <div>
              <label style="display: block; font-weight: 600; color: #6b7280; font-size: 13px; margin-bottom: 4px;">TYPE</label>
              <div id="review-type" style="color: #1f2937; font-size: 16px;">—</div>
            </div>

            <div>
              <label style="display: block; font-weight: 600; color: #6b7280; font-size: 13px; margin-bottom: 4px;">COMPARTMENTS</label>
              <div id="review-compartments" style="color: #1f2937; font-size: 16px;">—</div>
            </div>

            <div id="review-notes-section" style="display: none;">
              <label style="display: block; font-weight: 600; color: #6b7280; font-size: 13px; margin-bottom: 4px;">NOTES</label>
              <div id="review-notes" style="color: #1f2937; font-size: 16px;">—</div>
            </div>

            <div id="review-medications-section">
              <label style="display: block; font-weight: 600; color: #6b7280; font-size: 13px; margin-bottom: 4px;">MEDICATION ASSIGNMENTS</label>
              <div id="review-medications" style="color: #1f2937; font-size: 14px;">—</div>
            </div>
          </div>

          <div style="background: #f0fdf4; padding: 16px; border-radius: 8px; margin-top: 24px; border-left: 4px solid #10b981;">
            <p style="margin: 0; color: #065f46; font-size: 14px;">
              ✓ Everything looks good! Click "Create Pill Box" to finish.
            </p>
          </div>
        </div>
      </div>
    HTML
  end

  def render_wizard_navigation_buttons
    <<~HTML
      <div style="display: flex; justify-content: space-between; margin-top: 40px; padding-top: 20px; border-top: 2px solid #e5e7eb;">
        <button type="button" 
                data-action="click->wizard#previous" 
                data-wizard-target="prevBtn"
                style="display: none; padding: 12px 32px; background: #f3f4f6; color: #374151; border: 2px solid #d1d5db; border-radius: 8px; font-weight: 600; cursor: pointer;">
          ← Previous
        </button>
        
        <div style="flex: 1;"></div>
        
        <button type="button" 
                data-action="click->wizard#next" 
                data-wizard-target="nextBtn"
                style="padding: 12px 32px; background: #3b82f6; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer;">
          Next →
        </button>
        
        <button type="submit" 
                data-wizard-target="submitBtn"
                style="display: none; padding: 12px 32px; background: #10b981; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer;">
          Create Pill Box ✓
        </button>
      </div>
    HTML
  end

  def generate_index_html
    pillboxes = @pillboxes
    user = current_user
    
    <<~HTML
      #{render_header(user, 'My Pill Boxes')}
      <div class="container" style="max-width: 1200px; margin: 0 auto; padding: 20px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px;">
          <h1 style="margin: 0; font-size: 28px; color: #1f2937;">My Pill Boxes</h1>
          <a href="/pillboxes/wizard" style="background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600;">+ Create New Pill Box</a>
        </div>

        #{if pillboxes.any?
          "<div style=\"display: grid; gap: 20px;\">
            #{pillboxes.map { |pb| render_pillbox_card(pb) }.join('')}
          </div>"
        else
          render_empty_state
        end}
      </div>
      #{render_footer}
    HTML
  end

  def generate_show_html
    pillbox = @pillbox
    compartments = @compartments
    user = current_user

    <<~HTML
      #{render_header(user, pillbox.name)}
      <div class="container" style="max-width: 1200px; margin: 0 auto; padding: 20px;">
        <div style="margin-bottom: 20px;">
          <a href="/" style="color: #3b82f6; text-decoration: none;">← Back to Dashboard</a>
        </div>

        <div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin-bottom: 30px;">
          <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 20px;">
            <div>
              <h1 style="margin: 0 0 10px 0; font-size: 28px; color: #1f2937;">#{h(pillbox.name)}</h1>
              <div style="display: flex; gap: 12px; align-items: center;">
                <span style="background: #{pillbox.daily? ? '#3b82f6' : '#10b981'}; color: white; padding: 6px 16px; border-radius: 16px; font-size: 14px; font-weight: 600;">
                  #{pillbox.pillbox_type.capitalize}
                </span>
                <span style="color: #6b7280; font-size: 14px;">
                  #{compartments.count} compartments
                </span>
                <span style="color: #6b7280; font-size: 14px;">•</span>
                <span style="color: #{pillbox.needs_refill? ? '#ef4444' : '#10b981'}; font-size: 14px; font-weight: 500;">
                  #{pillbox.last_filled_at ? "Filled #{pillbox.days_since_filled} days ago" : "Never filled"}
                </span>
              </div>
            </div>
            <div style="display: flex; gap: 12px;">
              <a href="/pillboxes/#{pillbox.id}/fill" style="background: #10b981; color: white; padding: 10px 20px; border-radius: 8px; text-decoration: none; font-weight: 600;">📦 Fill Pill Box</a>
              <a href="/pillboxes/#{pillbox.id}/edit" style="background: #f3f4f6; color: #374151; padding: 10px 20px; border-radius: 8px; text-decoration: none; font-weight: 600; border: 2px solid #d1d5db;">Edit</a>
              <form action="/pillboxes/#{pillbox.id}" method="post" style="margin: 0;" onsubmit="return confirm('Are you sure you want to delete this pill box? This will permanently remove all compartments and medication assignments.');">
                <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
                <input type="hidden" name="_method" value="delete">
                <button type="submit" style="background: #ef4444; color: white; padding: 10px 20px; border-radius: 8px; font-weight: 600; border: none; cursor: pointer;">Delete</button>
              </form>
            </div>
          </div>

          #{if pillbox.notes.present?
            "<div style=\"background: #fef3c7; border-left: 4px solid #f59e0b; padding: 16px; border-radius: 6px; margin-bottom: 20px;\">
              <strong style=\"color: #92400e;\">Notes:</strong>
              <p style=\"margin: 8px 0 0 0; color: #78350f;\">#{h(pillbox.notes)}</p>
            </div>"
          else
            ""
          end}
        </div>

        #{if compartments.any?
          render_visual_pillbox(pillbox, compartments)
        else
          ""
        end}

        <div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #1f2937;">Compartment Details</h2>
          
          #{if compartments.any?
            "<div style=\"display: grid; gap: 16px;\">
              #{compartments.map { |comp| render_compartment_card(comp, pillbox) }.join('')}
            </div>"
          else
            "<div style=\"text-align: center; padding: 40px; color: #6b7280;\">
              <p style=\"font-size: 18px; margin: 0;\">No compartments yet</p>
              <p style=\"font-size: 14px; margin: 10px 0 0 0;\">#{pillbox.daily? ? 'Add compartments to organize your daily medications' : 'Compartments will be created automatically'}</p>
            </div>"
          end}
        </div>
      </div>
      #{render_footer}
    HTML
  end

  def generate_new_html(errors: [])
    user = current_user
    
    <<~HTML
      #{render_header(user, 'Create New Pill Box')}
      <div class="container" style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="margin-bottom: 20px;">
          <a href="/" style="color: #3b82f6; text-decoration: none;">← Back to Dashboard</a>
        </div>

        <div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <h1 style="margin: 0 0 10px 0; font-size: 28px; color: #1f2937;">Create New Pill Box</h1>
          <p style="color: #6b7280; margin: 0 0 30px 0;">Set up a virtual pill box to organize your medications</p>

          #{if errors.any?
            "<div style=\"background: #fee2e2; border-left: 4px solid #ef4444; padding: 16px; border-radius: 6px; margin-bottom: 20px;\">
              <strong style=\"color: #991b1b;\">Please fix the following errors:</strong>
              <ul style=\"margin: 10px 0 0 20px; color: #991b1b;\">
                #{errors.map { |error| "<li>#{error}</li>" }.join('')}
              </ul>
            </div>"
          else
            ""
          end}

          <form action="/pillboxes" method="post">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            
            <div style="margin-bottom: 24px;">
              <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Pill Box Name</label>
              <input type="text" name="pillbox[name]" required style="width: 100%; padding: 12px; border: 2px solid #d1d5db; border-radius: 8px; font-size: 16px;" placeholder="e.g., My Weekly Organizer">
            </div>

            <div style="margin-bottom: 24px;">
              <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 12px;">Pill Box Type</label>
              
              <div style="display: grid; gap: 12px;">
                <label style="display: flex; align-items: start; padding: 16px; border: 2px solid #d1d5db; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                  <input type="radio" name="pillbox[pillbox_type]" value="daily" required style="margin-top: 4px; margin-right: 12px;">
                  <div>
                    <strong style="display: block; color: #1f2937; margin-bottom: 4px;">📅 Daily Pill Box</strong>
                    <span style="color: #6b7280; font-size: 14px;">Organize medications by time of day (up to 12 compartments)</span>
                  </div>
                </label>

                <label style="display: flex; align-items: start; padding: 16px; border: 2px solid #d1d5db; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                  <input type="radio" name="pillbox[pillbox_type]" value="weekly" required style="margin-top: 4px; margin-right: 12px;">
                  <div>
                    <strong style="display: block; color: #1f2937; margin-bottom: 4px;">📆 Weekly Pill Box</strong>
                    <span style="color: #6b7280; font-size: 14px;">Organize medications by day of the week (7 compartments)</span>
                  </div>
                </label>
              </div>
            </div>

            <div style="margin-bottom: 24px;">
              <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Notes (Optional)</label>
              <textarea name="pillbox[notes]" rows="3" style="width: 100%; padding: 12px; border: 2px solid #d1d5db; border-radius: 8px; font-size: 16px; font-family: inherit;" placeholder="Any additional notes about this pill box..."></textarea>
            </div>

            <div style="display: flex; gap: 12px; justify-content: flex-end;">
              <a href="/" style="background: #f3f4f6; color: #374151; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600; border: 2px solid #d1d5db;">Cancel</a>
              <button type="submit" style="background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; border: none; font-weight: 600; font-size: 16px; cursor: pointer;">Create Pill Box</button>
            </div>
          </form>
        </div>
      </div>
      #{render_footer}
    HTML
  end

  def generate_edit_html(errors: [])
    pillbox = @pillbox
    compartments = @compartments
    medications = @medications
    user = current_user
    
    <<~HTML
      #{render_header(user, "Edit #{h(pillbox.name)}")}
      <div class="container" style="max-width: 1000px; margin: 0 auto; padding: 20px;">
        <div style="margin-bottom: 20px;">
          <a href="/pillboxes/#{pillbox.id}" style="color: #3b82f6; text-decoration: none;">← Back to Pill Box</a>
        </div>

        <div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <h1 style="margin: 0 0 10px 0; font-size: 28px; color: #1f2937;">Edit Pill Box</h1>
          <p style="color: #6b7280; margin: 0 0 30px 0;">Update pill box name, notes, and manage medication assignments</p>

          #{if errors.any?
            "<div style=\"background: #fee2e2; border-left: 4px solid #ef4444; padding: 16px; border-radius: 6px; margin-bottom: 20px;\">
              <strong style=\"color: #991b1b;\">Please fix the following errors:</strong>
              <ul style=\"margin: 10px 0 0 20px; color: #991b1b;\">
                #{errors.map { |error| "<li>#{error}</li>" }.join('')}
              </ul>
            </div>"
          else
            ""
          end}

          <form action="/pillboxes/#{pillbox.id}" method="post">
            <input type="hidden" name="_method" value="patch">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            
            <div style="margin-bottom: 24px;">
              <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Pill Box Name</label>
              <input type="text" name="pillbox[name]" value="#{h(pillbox.name)}" maxlength="15" required style="width: 100%; padding: 12px; border: 2px solid #d1d5db; border-radius: 8px; font-size: 16px;">
            </div>

            <div style="margin-bottom: 24px;">
              <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Type</label>
              <div style="padding: 12px; background: #f3f4f6; border-radius: 8px; color: #6b7280;">
                #{pillbox.daily? ? '📅' : '📆'} #{pillbox.pillbox_type.capitalize} - #{compartments.count} compartments (cannot be changed)
              </div>
            </div>

            <div style="margin-bottom: 24px;">
              <label style="display: block; font-weight: 600; color: #374151; margin-bottom: 8px;">Notes</label>
              <textarea name="pillbox[notes]" rows="3" style="width: 100%; padding: 12px; border: 2px solid #d1d5db; border-radius: 8px; font-size: 16px; font-family: inherit;">#{h(pillbox.notes)}</textarea>
            </div>

            <div style="margin-bottom: 24px;">
              <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #1f2937; border-bottom: 2px solid #e5e7eb; padding-bottom: 12px;">Medication Assignments</h2>
              <div style="background: #eff6ff; padding: 16px; border-radius: 8px; border-left: 4px solid #3b82f6; margin-bottom: 20px;">
                <p style="margin: 0; color: #1e40af; font-size: 14px;">
                  💊 Add or remove medications from each compartment. Set quantities for each medication.
                </p>
              </div>

              #{if medications.any?
                "<div style=\"display: grid; gap: 20px;\">
                  #{compartments.map { |comp| render_edit_compartment_section(comp, medications) }.join('')}
                </div>"
              else
                "<div style=\"background: #fee2e2; padding: 20px; border-radius: 8px; border-left: 4px solid #ef4444; text-align: center;\">
                  <p style=\"margin: 0 0 12px 0; color: #991b1b; font-weight: 600;\">No Active Medications</p>
                  <p style=\"margin: 0; color: #991b1b; font-size: 14px;\">
                    You need active medications to assign to compartments.
                  </p>
                  <a href=\"/medications/new\" style=\"display: inline-block; margin-top: 16px; background: #ef4444; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-weight: 600;\">
                    + Add Medication
                  </a>
                </div>"
              end}
            </div>

            <div style="display: flex; gap: 12px; justify-content: flex-end;">
              <a href="/pillboxes/#{pillbox.id}" style="background: #f3f4f6; color: #374151; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600; border: 2px solid #d1d5db;">Cancel</a>
              <button type="submit" style="background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; border: none; font-weight: 600; font-size: 16px; cursor: pointer;">Update Pill Box</button>
            </div>
          </form>
        </div>
      </div>
      
      <script>
        // Handle checkbox/quantity field interaction
        document.addEventListener('DOMContentLoaded', () => {
          const checkboxes = document.querySelectorAll('.med-checkbox');
          
          checkboxes.forEach(checkbox => {
            checkbox.addEventListener('change', function() {
              const medId = this.dataset.medId;
              const compId = this.dataset.compId;
              const quantityInput = document.querySelector(`.quantity-input[data-med-id="${medId}"][data-comp-id="${compId}"]`);
              
              if (quantityInput) {
                quantityInput.disabled = !this.checked;
                if (!this.checked) {
                  quantityInput.value = '';
                } else if (quantityInput.value === '' || quantityInput.value === '0') {
                  quantityInput.value = '1';
                }
              }
            });
          });
        });
      </script>
      
      #{render_footer}
    HTML
  end

  def generate_fill_html
    pillbox = @pillbox
    compartments = @compartments
    user = current_user

    <<~HTML
      #{render_header(user, "Fill #{h(pillbox.name)}")}
      <div class="container" style="max-width: 900px; margin: 0 auto; padding: 20px;">
        <div style="margin-bottom: 20px;">
          <a href="/pillboxes/#{pillbox.id}" style="color: #3b82f6; text-decoration: none;">← Back to Pill Box</a>
        </div>

        <div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="margin: 0 0 10px 0; font-size: 28px; color: #1f2937;">Fill Your Pill Box</h1>
            <p style="color: #6b7280; margin: 0;">Tap each medication as you add it to your pill box</p>
          </div>

          <form action="/pillboxes/#{pillbox.id}/fill" method="post" id="fillForm">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            
            <div style="display: grid; gap: 16px; margin-bottom: 30px;">
              #{compartments.map { |comp| render_fill_compartment(comp, pillbox) }.join('')}
            </div>

            <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 16px; border-radius: 6px; margin-bottom: 24px;">
              <strong style="color: #92400e;">💡 Tip:</strong>
              <p style="margin: 8px 0 0 0; color: #78350f;">Tap each medication as you physically add it to your pill box. When all medications in a compartment are checked, the compartment will highlight to show it's complete.</p>
            </div>

            <div style="display: flex; gap: 12px; justify-content: flex-end;">
              <a href="/pillboxes/#{pillbox.id}" style="background: #f3f4f6; color: #374151; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600; border: 2px solid #d1d5db;">Cancel</a>
              <button type="submit" style="background: #10b981; color: white; padding: 12px 24px; border-radius: 8px; border: none; font-weight: 600; font-size: 16px; cursor: pointer;">✓ Mark as Filled</button>
            </div>
          </form>
        </div>
      </div>

      <script>
        function getMedicationColor(medName) {
          // Generate consistent color based on medication name
          let hash = 0;
          for (let i = 0; i < medName.length; i++) {
            hash = medName.charCodeAt(i) + ((hash << 5) - hash);
          }
          const colors = [
            '#f59e0b', // amber
            '#3b82f6', // blue
            '#8b5cf6', // purple
            '#ec4899', // pink
            '#06b6d4', // cyan
            '#10b981', // emerald
            '#f43f5e', // rose
            '#6366f1', // indigo
          ];
          return colors[Math.abs(hash) % colors.length];
        }

        document.addEventListener('DOMContentLoaded', () => {
          const medButtons = document.querySelectorAll('.med-button');
          
          medButtons.forEach(button => {
            const medName = button.dataset.medName;
            const borderColor = getMedicationColor(medName);
            button.style.borderColor = borderColor;
            
            button.addEventListener('click', function(e) {
              e.preventDefault();
              const checkbox = this.querySelector('input[type="checkbox"]');
              checkbox.checked = !checkbox.checked;
              
              // Update button appearance
              if (checkbox.checked) {
                this.style.background = 'rgba(0, 0, 0, 0.05)';
                this.querySelector('.checkmark').style.display = 'inline';
              } else {
                this.style.background = 'white';
                this.querySelector('.checkmark').style.display = 'none';
              }
              
              // Check if all medications in this compartment are checked
              const compartmentId = this.dataset.compartmentId;
              const compartmentDiv = document.querySelector(`[data-compartment="${compartmentId}"]`);
              const allMeds = compartmentDiv.querySelectorAll('.med-button input[type="checkbox"]');
              const checkedMeds = compartmentDiv.querySelectorAll('.med-button input[type="checkbox"]:checked');
              
              if (allMeds.length > 0 && allMeds.length === checkedMeds.length) {
                compartmentDiv.style.background = 'rgba(16, 185, 129, 0.1)';
                compartmentDiv.style.borderColor = '#10b981';
              } else {
                compartmentDiv.style.background = '#f9fafb';
                compartmentDiv.style.borderColor = '#e5e7eb';
              }
            });
          });
        });
      </script>

      #{render_footer}
    HTML
  end

  def render_fill_compartment(compartment, pillbox)
    medications = compartment.medications
    
    <<~HTML
      <div data-compartment="#{compartment.id}" style="background: #f9fafb; border: 2px solid #e5e7eb; border-radius: 8px; padding: 20px; transition: all 0.3s ease;">
        <div style="font-weight: 600; font-size: 18px; color: #1f2937; margin-bottom: 16px;">
          #{h(compartment.display_name)}
        </div>
        #{if medications.any?
          "<div style=\"display: grid; gap: 10px;\">
            #{medications.map { |med|
              quantity = compartment.compartment_medications.find_by(medication_id: med.id)&.quantity || 1
              render_medication_button(med, quantity, compartment.id)
            }.join('')}
          </div>"
        else
          "<div style=\"color: #9ca3af; font-style: italic; font-size: 14px; text-align: center; padding: 20px;\">No medications assigned</div>"
        end}
      </div>
    HTML
  end

  def render_medication_button(medication, quantity, compartment_id)
    pills_html = (1..quantity).map { render_pill(medication.color, medication.shape) }.join('')
    
    <<~HTML
      <button type="button" class="med-button" data-med-name="#{h(medication.name)}" data-compartment-id="#{compartment_id}" style="display: flex; align-items: center; gap: 12px; padding: 12px; background: white; border-radius: 8px; border: 4px solid; cursor: pointer; text-align: left; width: 100%; transition: all 0.2s ease;">
        <input type="checkbox" name="medications[#{compartment_id}][#{medication.id}]" value="1" style="display: none;">
        <span class="checkmark" style="display: none; color: #10b981; font-size: 24px; font-weight: bold; flex-shrink: 0;">✓</span>
        <div style="flex: 1; min-width: 0;">
          <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
            <div style="font-weight: 600; color: #1f2937; font-size: 15px;">#{h(medication.name)}</div>
            <div style="color: #6b7280; font-size: 13px; white-space: nowrap;">#{quantity} pill#{'s' if quantity > 1}</div>
          </div>
          <div style="display: flex; gap: 4px; flex-wrap: wrap;">
            #{pills_html}
          </div>
        </div>
      </button>
    HTML
  end

  def render_pill(color, shape)
    # Default color if none provided
    pill_color = color.presence || '#9ca3af'
    
    # Render pill based on shape
    case shape
    when 'circle'
      <<~HTML
        <div style="width: 24px; height: 24px; background: #{pill_color}; border-radius: 50%; border: 2px solid rgba(0,0,0,0.15); box-shadow: 0 1px 2px rgba(0,0,0,0.1);"></div>
      HTML
    when 'square'
      <<~HTML
        <div style="width: 24px; height: 24px; background: #{pill_color}; border-radius: 4px; border: 2px solid rgba(0,0,0,0.15); box-shadow: 0 1px 2px rgba(0,0,0,0.1);"></div>
      HTML
    when 'triangle'
      <<~HTML
        <div style="width: 0; height: 0; border-left: 12px solid transparent; border-right: 12px solid transparent; border-bottom: 24px solid #{pill_color}; filter: drop-shadow(0 1px 2px rgba(0,0,0,0.1));"></div>
      HTML
    else
      # Default to circle
      <<~HTML
        <div style="width: 24px; height: 24px; background: #{pill_color}; border-radius: 50%; border: 2px solid rgba(0,0,0,0.15); box-shadow: 0 1px 2px rgba(0,0,0,0.1);"></div>
      HTML
    end
  end

  def render_pillbox_card(pillbox)
    <<~HTML
      <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); border-left: 4px solid #{pillbox.daily? ? '#3b82f6' : '#10b981'};">
        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 12px;">
          <div>
            <h3 style="margin: 0 0 8px 0; font-size: 20px; color: #1f2937;">#{pillbox.name}</h3>
            <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
              <span style="background: #{pillbox.daily? ? '#3b82f6' : '#10b981'}; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">
                #{pillbox.pillbox_type.capitalize}
              </span>
              <span style="color: #6b7280; font-size: 14px;">#{pillbox.compartments.count} compartments</span>
              <span style="color: #6b7280; font-size: 14px;">•</span>
              <span style="color: #6b7280; font-size: 14px;">#{pillbox.total_medications} medications</span>
            </div>
          </div>
          <a href="/pillboxes/#{pillbox.id}" style="background: #3b82f6; color: white; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-weight: 600; font-size: 14px;">View</a>
        </div>
        
        <div style="margin-top: 12px; padding-top: 12px; border-top: 1px solid #e5e7eb;">
          <div style="display: flex; justify-content: space-between; align-items: center;">
            <span style="color: #{pillbox.needs_refill? ? '#ef4444' : '#10b981'}; font-size: 13px; font-weight: 500;">
              #{pillbox.last_filled_at ? "Filled #{pillbox.days_since_filled} days ago" : "Never filled"}
              #{pillbox.needs_refill? ? ' • Needs refill' : ''}
            </span>
            <div style="display: flex; gap: 8px;">
              <a href="/pillboxes/#{pillbox.id}/edit" style="color: #3b82f6; text-decoration: none; font-size: 14px; font-weight: 500;">Edit</a>
            </div>
          </div>
        </div>
      </div>
    HTML
  end

  def render_compartment_card(compartment, pillbox)
    meds = compartment.compartment_medications.includes(:medication)
    
    <<~HTML
      <div style="background: #f9fafb; padding: 16px; border-radius: 8px; border: 2px solid #e5e7eb;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <h4 style="margin: 0; font-size: 16px; color: #1f2937;">#{h(compartment.display_name)}</h4>
          <span style="background: #e5e7eb; color: #374151; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;">
            Position #{compartment.position}
          </span>
        </div>
        
        #{if meds.any?
          "<div style=\"display: grid; gap: 8px;\">
            #{meds.map { |cm| 
              "<div style=\"display: flex; justify-content: space-between; align-items: center; padding: 10px; background: white; border-radius: 6px;\">
                <div>
                  <strong style=\"color: #1f2937;\">#{cm.medication.name}</strong>
                  <span style=\"color: #6b7280; font-size: 14px; margin-left: 8px;\">#{cm.medication.dosage}</span>
                </div>
                <span style=\"background: #3b82f6; color: white; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;\">
                  × #{cm.quantity}
                </span>
              </div>"
            }.join('')}
          </div>"
        else
          "<p style=\"color: #9ca3af; font-size: 14px; margin: 0; text-align: center; padding: 12px 0;\">No medications assigned</p>"
        end}
      </div>
    HTML
  end

  def render_visual_pillbox(pillbox, compartments)
    # Determine grid layout based on compartment count
    cols = if pillbox.weekly?
      7 # Weekly: 7 days in a row
    elsif compartments.count <= 4
      compartments.count # 1-4: single row
    elsif compartments.count <= 6
      3 # 5-6: 2 rows of 3
    elsif compartments.count <= 9
      3 # 7-9: 3 rows of 3
    else
      4 # 10-12: 3 rows of 4
    end

    <<~HTML
      <div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin-bottom: 30px;">
        <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #1f2937;">Visual Layout</h2>
        
        <div style="display: grid; grid-template-columns: repeat(#{cols}, 1fr); gap: 16px; max-width: #{cols * 150}px; margin: 0 auto;">
          #{compartments.map { |comp| render_visual_compartment(comp) }.join('')}
        </div>
      </div>
    HTML
  end

  def render_visual_compartment(compartment)
    meds = compartment.compartment_medications.includes(:medication)
    total_pills = meds.sum(&:quantity)
    has_meds = meds.any?

    <<~HTML
      <div style="background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%); padding: 16px; border-radius: 12px; border: 3px solid #{has_meds ? '#3b82f6' : '#d1d5db'}; min-height: 200px; display: flex; flex-direction: column; position: relative; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 12px;">
          <div style="font-weight: 700; font-size: 14px; color: #1f2937; margin-bottom: 4px;">#{h(compartment.display_name)}</div>
          <div style="font-size: 11px; color: #6b7280;">Pos. #{compartment.position}</div>
        </div>
        
        <div style="flex: 1; display: flex; flex-direction: column; justify-content: center; gap: 8px; min-height: 120px;">
          #{if has_meds
            meds.map { |cm|
              pills_html = (1..cm.quantity).map { render_pill(cm.medication.color, cm.medication.shape) }.join('')
              "<div style=\"display: flex; align-items: center; gap: 8px; padding: 8px; background: white; border-radius: 6px; border: 1px solid #e5e7eb;\">
                <div style=\"flex: 1; min-width: 0;\">
                  <div style=\"font-weight: 600; font-size: 12px; color: #1f2937; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;\">#{h(cm.medication.name)}</div>
                  <div style=\"font-size: 10px; color: #6b7280;\">×#{cm.quantity}</div>
                </div>
                <div style=\"display: flex; gap: 3px; flex-wrap: wrap; max-width: 60px;\">
                  #{pills_html}
                </div>
              </div>"
            }.join('')
          else
            "<div style=\"text-align: center; color: #9ca3af; font-size: 13px;\">
              <div style=\"font-size: 32px; margin-bottom: 4px; opacity: 0.5;\">💊</div>
              <div>Empty</div>
            </div>"
          end}
        </div>
      </div>
    HTML
  end

  def render_edit_compartment_section(compartment, medications)
    current_meds = compartment.compartment_medications.includes(:medication).index_by(&:medication_id)
    
    <<~HTML
      <div style="background: #f9fafb; border: 2px solid #e5e7eb; border-radius: 8px; padding: 20px;">
        <h3 style="margin: 0 0 12px 0; font-size: 18px; color: #1f2937; display: flex; align-items: center; gap: 8px;">
          <span>#{h(compartment.display_name)}</span>
          <span style="background: #e5e7eb; color: #6b7280; padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">Pos. #{compartment.position}</span>
        </h3>
        
        <div style="display: grid; gap: 12px;">
          #{medications.map { |med|
            cm = current_meds[med.id]
            current_qty = cm ? cm.quantity : 0
            
            "<div style=\"background: white; padding: 12px; border-radius: 6px; border: 2px solid #{cm ? '#3b82f6' : '#e5e7eb'};\">
              <div style=\"display: flex; align-items: center; gap: 12px;\">
                <input type=\"checkbox\" 
                       class=\"med-checkbox\"
                       data-med-id=\"#{med.id}\"
                       data-comp-id=\"#{compartment.id}\"
                       #{cm ? 'checked' : ''}
                       style=\"width: 18px; height: 18px; cursor: pointer;\">
                <div style=\"flex: 1;\">
                  <strong style=\"color: #1f2937;\">#{h(med.name)}</strong>
                  <span style=\"color: #6b7280; font-size: 14px; margin-left: 8px;\">#{h(med.dosage)}</span>
                </div>
                <div style=\"display: flex; align-items: center; gap: 6px;\">
                  <label style=\"color: #6b7280; font-size: 13px; font-weight: 500;\">Qty:</label>
                  <input type=\"number\" 
                         name=\"medication_assignments[#{compartment.id}][medications][#{med.id}][quantity]\" 
                         value=\"#{current_qty > 0 ? current_qty : ''}\"
                         min=\"1\"
                         max=\"99\"
                         class=\"quantity-input\"
                         data-med-id=\"#{med.id}\"
                         data-comp-id=\"#{compartment.id}\"
                         #{cm ? '' : 'disabled'}
                         placeholder=\"0\"
                         style=\"width: 60px; padding: 4px 8px; border: 2px solid #d1d5db; border-radius: 4px; text-align: center; font-size: 13px; font-weight: 600;\">
                </div>
              </div>
            </div>"
          }.join('')}
        </div>
      </div>
    HTML
  end

  def render_pill_visual(medication)
    # Generate consistent color based on medication name
    color = generate_pill_color(medication.name)
    
    <<~HTML
      <div style="width: 20px; height: 20px; background: #{color}; border-radius: 50%; border: 2px solid rgba(0,0,0,0.1); box-shadow: 0 1px 2px rgba(0,0,0,0.1);" title="#{h(medication.name)}"></div>
    HTML
  end

  def generate_pill_color(name)
    # Generate a consistent color based on the medication name
    hash = name.bytes.sum
    colors = [
      '#ef4444', # red
      '#f59e0b', # orange
      '#eab308', # yellow
      '#84cc16', # lime
      '#10b981', # green
      '#14b8a6', # teal
      '#06b6d4', # cyan
      '#3b82f6', # blue
      '#6366f1', # indigo
      '#8b5cf6', # violet
      '#a855f7', # purple
      '#ec4899', # pink
    ]
    colors[hash % colors.length]
  end

  def render_empty_state
    <<~HTML
      <div style="background: white; padding: 60px 40px; border-radius: 12px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="font-size: 64px; margin-bottom: 20px;">📦</div>
        <h2 style="margin: 0 0 12px 0; font-size: 24px; color: #1f2937;">No pill boxes yet</h2>
        <p style="color: #6b7280; margin: 0 0 30px 0; font-size: 16px;">Create your first virtual pill box to organize your medications</p>
        <a href="/pillboxes/new" style="background: #3b82f6; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block;">Create Your First Pill Box</a>
      </div>
    HTML
  end

  def render_header(user, title)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{title} - Pill Boxer</title>
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
          body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f9fafb; }
          * { box-sizing: border-box; }
          .brand-icon { width: 32px; height: 32px; vertical-align: middle; margin-right: 8px; border-radius: 6px; }
        </style>
      </head>
      <body>
        <nav style="background: white; border-bottom: 1px solid #e5e7eb; padding: 16px 20px; position: sticky; top: 0; z-index: 100; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
          <div style="max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center;">
            <a href="/" style="font-size: 20px; font-weight: 700; color: #1f2937; text-decoration: none; display: flex; align-items: center;">
              <img src="/pb-icon-large.png" alt="Pill Boxer" class="brand-icon"> Pill Boxer
            </a>
            <div style="display: flex; align-items: center; gap: 24px;">
              <a href="/" style="color: #6b7280; text-decoration: none; font-weight: 500;">Home</a>
              <a href="/medications" style="color: #6b7280; text-decoration: none; font-weight: 500;">Medications</a>
              <a href="/pillboxes" style="color: #6b7280; text-decoration: none; font-weight: 500;">Pill Boxes</a>
              <span style="color: #6b7280; border-left: 1px solid #e5e7eb; padding-left: 24px;">👋 #{user.name}</span>
              <a href="/logout" style="color: #ef4444; text-decoration: none; font-weight: 500;">Logout</a>
            </div>
          </div>
        </nav>
    HTML
  end

  def render_footer
    <<~HTML
        <footer style="text-align: center; padding: 40px 20px; color: #9ca3af; font-size: 14px;">
          <p style="margin: 0;">💊 Pill Boxer - Your Personal Medication Manager</p>
        </footer>
      </body>
      </html>
    HTML
  end
end
