module WizardHelper
  def render_boxxy_character(message: "Hi! I'm Boxxy!", size: "medium")
    size_class = case size
                 when "small" then "width: 100px; height: 100px;"
                 when "medium" then "width: 150px; height: 150px;"
                 when "large" then "width: 200px; height: 200px;"
                 else "width: 150px; height: 150px;"
                 end

    <<~HTML
      <div style="text-align: center; margin: 20px 0;">
        <div style="display: inline-block; position: relative;">
          <img src="/assets/boxxy.svg" alt="Boxxy the Boxer" style="#{size_class}">
          #{if message
            "<div style=\"position: relative; margin-top: -20px;\">
              <div style=\"background: white; border: 3px solid #3b82f6; border-radius: 20px; padding: 12px 20px; display: inline-block; box-shadow: 0 4px 12px rgba(0,0,0,0.15); max-width: 300px;\">
                <div style=\"position: absolute; top: -10px; left: 50%; transform: translateX(-50%); width: 0; height: 0; border-left: 10px solid transparent; border-right: 10px solid transparent; border-bottom: 10px solid #3b82f6;\"></div>
                <p style=\"margin: 0; color: #1f2937; font-size: 14px; font-weight: 500;\">#{message}</p>
              </div>
            </div>"
          else
            ""
          end}
        </div>
      </div>
    HTML
  end

  def render_wizard_progress(current_step:, total_steps:, steps_labels: [])
    steps = steps_labels.presence || (1..total_steps).map { |i| "Step #{i}" }
    
    <<~HTML
      <div style="margin: 30px 0;">
        <!-- Progress Bar -->
        <div style="background: #e5e7eb; height: 8px; border-radius: 10px; overflow: hidden; margin-bottom: 20px;">
          <div data-wizard-target="progress" 
               style="background: linear-gradient(90deg, #3b82f6 0%, #2563eb 100%); height: 100%; width: #{(current_step.to_f / total_steps * 100).round}%; transition: width 0.3s ease;"
               role="progressbar" 
               aria-valuenow="#{(current_step.to_f / total_steps * 100).round}" 
               aria-valuemin="0" 
               aria-valuemax="100">
          </div>
        </div>

        <!-- Step Indicators -->
        <div style="display: flex; justify-content: space-between; align-items: center;">
          #{steps.map.with_index { |label, index|
            step_num = index + 1
            is_current = step_num == current_step
            is_completed = step_num < current_step
            is_upcoming = step_num > current_step

            status_class = if is_completed
              "background: #10b981; color: white; border-color: #10b981;"
            elsif is_current
              "background: #3b82f6; color: white; border-color: #3b82f6; box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.2);"
            else
              "background: white; color: #9ca3af; border-color: #d1d5db;"
            end

            "<div class=\"step-indicator #{is_current ? 'active' : ''} #{is_completed ? 'completed' : ''} #{is_upcoming ? 'upcoming' : ''}\" 
                  style=\"flex: 1; text-align: center; cursor: pointer;\"
                  data-action=\"click->wizard#goToStep\"
                  data-step=\"#{step_num}\">
              <div style=\"width: 40px; height: 40px; border-radius: 50%; border: 3px solid; display: inline-flex; align-items: center; justify-content: center; font-weight: 700; margin-bottom: 8px; transition: all 0.3s; #{status_class}\">
                #{is_completed ? '✓' : step_num}
              </div>
              <div style=\"font-size: 12px; color: #{is_current ? '#1f2937' : '#6b7280'}; font-weight: #{is_current ? '600' : '400'};\">
                #{label}
              </div>
            </div>"
          }.join('')}
        </div>
      </div>
    HTML
  end

  def render_wizard_navigation(current_step:, total_steps:, prev_url: nil, next_text: nil)
    is_first = current_step == 1
    is_last = current_step == total_steps
    next_button_text = next_text || (is_last ? 'Create Pill Box' : 'Next Step →')

    <<~HTML
      <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 40px; padding-top: 30px; border-top: 2px solid #e5e7eb;">
        #{if is_first
          "<div></div>"
        else
          "<button type=\"button\" 
                  data-wizard-target=\"prevButton\" 
                  data-action=\"click->wizard#previous\"
                  style=\"background: #f3f4f6; color: #374151; padding: 12px 24px; border-radius: 8px; border: 2px solid #d1d5db; font-weight: 600; cursor: pointer; transition: all 0.2s;\">
            ← Previous Step
          </button>"
        end}

        <div style=\"text-align: center; color: #6b7280; font-size: 14px;\">
          Step #{current_step} of #{total_steps}
        </div>

        <button type=\"#{is_last ? 'submit' : 'button'}\" 
                data-wizard-target=\"nextButton\" 
                data-action=\"click->wizard#next\"
                style=\"background: #{is_last ? '#10b981' : '#3b82f6'}; color: white; padding: 12px 24px; border-radius: 8px; border: none; font-weight: 600; font-size: 16px; cursor: pointer; transition: all 0.2s;\">
          #{next_button_text}
        </button>
      </div>
    HTML
  end

  def render_wizard_step_container(step_number:, visible: false, &block)
    display_style = visible ? "display: block;" : "display: none;"
    
    <<~HTML
      <div data-wizard-target="step" 
           data-step="#{step_number}"
           class="wizard-step #{visible ? '' : 'hidden'}"
           style="#{display_style}">
        #{block.call if block_given?}
      </div>
    HTML
  end
end
