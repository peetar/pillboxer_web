class MedicationsController < ApplicationController
  before_action :require_login
  before_action :set_medication, only: [:show, :edit, :update, :destroy, :toggle_taken]
  
  def index
    @medications = current_user.medications.where(active: true).includes(:schedules, :medication_logs)
    html = generate_medications_index_html(@medications)
    render html: html.html_safe
  end
  
  def show
    @logs = @medication.medication_logs.order(scheduled_for: :desc).limit(10)
  end
  
  def new
    @medication = current_user.medications.build
    html = generate_new_medication_html(@medication)
    render html: html.html_safe
  end
  
  def create
    @medication = current_user.medications.build(medication_params)
    
    if @medication.save
      redirect_to root_path, notice: "#{@medication.name} was added successfully!"
    else
      html = generate_new_medication_html(@medication)
      render html: html.html_safe, status: :unprocessable_entity
    end
  end
  
  def edit
    html = generate_edit_medication_html(@medication)
    render html: html.html_safe
  end
  
  def update
    if @medication.update(medication_params)
      redirect_to root_path, notice: "#{@medication.name} was updated successfully!"
    else
      html = generate_edit_medication_html(@medication)
      render html: html.html_safe, status: :unprocessable_entity
    end
  end
  
  def destroy
    name = @medication.name
    @medication.update(active: false)
    redirect_to root_path, notice: "#{name} was removed successfully!"
  end
  
  def toggle_taken
    log = @medication.medication_logs.find_or_create_by(
      scheduled_for: Date.current,
      taken_at: Time.current
    )
    
    log.update(taken: !log.taken?)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_path) }
    end
  end
  
  private
  
  def set_medication
    @medication = current_user.medications.find(params[:id])
  end
  
  def medication_params
    params.require(:medication).permit(:name, :dosage, :frequency, :instructions, :color, :shape, :active)
  end

  def generate_navigation_html(user)
    <<~HTML
      <nav class="navbar">
        <div class="navbar-container">
          <div class="navbar-brand">
            <a href="/"><img src="/pb-icon-large.png" alt="Pill Boxer" class="brand-icon"> Pill Boxer</a>
          </div>
          
          <div class="navbar-nav">
            <a href="/" class="nav-link">Home</a>
            <a href="/medications" class="nav-link">Medications</a>
            <a href="/pillboxes" class="nav-link">Pill Boxes</a>
            
            <div class="navbar-user">
              <span class="user-name">👋 #{user.name}</span>
              <a href="/logout" class="logout-link">Logout</a>
            </div>
          </div>
        </div>
      </nav>
    HTML
  end

  def generate_base_styles
    <<~CSS
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        background-color: #f9fafb;
      }
      
      /* Navigation Styles */
      .navbar {
        background-color: #ffffff;
        border-bottom: 1px solid #e5e7eb;
        padding: 0;
        position: sticky;
        top: 0;
        z-index: 100;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }
      
      .navbar-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 16px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .navbar-brand a {
        font-size: 20px;
        font-weight: 700;
        color: #1f2937;
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 8px;
      }
      
      .brand-icon {
        width: 32px;
        height: 32px;
        border-radius: 6px;
      }
      
      .navbar-brand a:hover {
        color: #3b82f6;
      }
      
      .navbar-nav {
        display: flex;
        align-items: center;
        gap: 24px;
      }
      
      .nav-link {
        color: #6b7280;
        text-decoration: none;
        font-weight: 500;
        padding: 8px 16px;
        border-radius: 6px;
        transition: all 0.2s;
      }
      
      .nav-link:hover {
        color: #3b82f6;
        background-color: #eff6ff;
      }
      
      .navbar-user {
        display: flex;
        align-items: center;
        gap: 16px;
        border-left: 1px solid #e5e7eb;
        padding-left: 24px;
      }
      
      .user-name {
        font-size: 14px;
        color: #374151;
        font-weight: 500;
      }
      
      .logout-link {
        color: #6b7280;
        text-decoration: none;
        font-size: 14px;
        padding: 6px 12px;
        border-radius: 4px;
        border: 1px solid #d1d5db;
        transition: all 0.2s;
      }
      
      .logout-link:hover {
        background-color: #f9fafb;
        border-color: #9ca3af;
        color: #374151;
      }
    CSS
  end

  def generate_new_medication_html(medication)
    errors_html = if medication.errors.any?
      error_messages = medication.errors.full_messages.map { |msg| "<li>#{msg}</li>" }.join('')
      <<~HTML
        <div class="error-messages">
          <h3>#{medication.errors.count} error(s) prohibited this medication from being saved:</h3>
          <ul>#{error_messages}</ul>
        </div>
      HTML
    else
      ''
    end

    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Add New Medication - Pill Boxer</title>
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
          #{generate_base_styles}
          
          .form-container {
            max-width: 480px;
            margin: 0 auto;
            padding: 20px;
          }
          
          .form-group {
            margin-bottom: 20px;
          }
          
          .form-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #374151;
          }
          
          .form-group input,
          .form-group textarea,
          .form-group select {
            width: 100%;
            padding: 12px;
            border: 2px solid #d1d5db;
            border-radius: 8px;
            font-size: 16px;
            box-sizing: border-box;
          }
          
          .form-group input:focus,
          .form-group textarea:focus,
          .form-group select:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
          }
          
          .btn {
            display: inline-block;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            text-decoration: none;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s;
          }
          
          .btn-primary {
            background-color: #3b82f6;
            color: white;
            width: 100%;
          }
          
          .btn-primary:hover {
            background-color: #2563eb;
          }
          
          .btn-secondary {
            background-color: #f3f4f6;
            color: #374151;
            border: 2px solid #d1d5db;
          }
          
          .btn-secondary:hover {
            background-color: #e5e7eb;
          }
          
          .form-actions {
            display: flex;
            gap: 12px;
            margin-top: 30px;
          }
          
          .form-actions .btn {
            flex: 1;
          }
          
          .error-messages {
            background-color: #fef2f2;
            border: 1px solid #fecaca;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 20px;
            color: #dc2626;
          }
          
          .error-messages ul {
            margin: 0;
            padding-left: 20px;
          }
        </style>
      </head>
      <body>
        #{generate_navigation_html(current_user)}
        
        <div class="form-container">
          <h1>Add New Medication</h1>
          
          #{errors_html}
          
          <form action="/medications" method="post">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            
            <div class="form-group">
              <label for="medication_name">Medication Name *</label>
              <input type="text" id="medication_name" name="medication[name]" value="#{h(medication.name)}" placeholder="e.g., Lisinopril" required>
            </div>
            
            <div class="form-group">
              <label for="medication_dosage">Dosage *</label>
              <input type="text" id="medication_dosage" name="medication[dosage]" value="#{medication.dosage}" placeholder="e.g., 10mg" required>
            </div>
            
            <div class="form-group">
              <label for="medication_frequency">Frequency *</label>
              <select id="medication_frequency" name="medication[frequency]" required>
                <option value="">Select frequency...</option>
                <option value="once_daily" #{medication.frequency == 'once_daily' ? 'selected' : ''}>Once daily</option>
                <option value="twice_daily" #{medication.frequency == 'twice_daily' ? 'selected' : ''}>Twice daily</option>
                <option value="three_times_daily" #{medication.frequency == 'three_times_daily' ? 'selected' : ''}>Three times daily</option>
                <option value="four_times_daily" #{medication.frequency == 'four_times_daily' ? 'selected' : ''}>Four times daily</option>
                <option value="as_needed" #{medication.frequency == 'as_needed' ? 'selected' : ''}>As needed</option>
                <option value="other" #{medication.frequency == 'other' ? 'selected' : ''}>Other</option>
              </select>
            </div>
            
            <div class="form-group">
              <label for="medication_instructions">Instructions</label>
              <textarea id="medication_instructions" name="medication[instructions]" rows="3" placeholder="e.g., Take with food, avoid alcohol">#{medication.instructions}</textarea>
            </div>
            
            <div class="form-group">
              <label for="medication_color">Pill Color</label>
              <select id="medication_color" name="medication[color]">
                <option value="">Select color...</option>
                <option value="white" #{medication.color == 'white' ? 'selected' : ''}>White</option>
                <option value="blue" #{medication.color == 'blue' ? 'selected' : ''}>Blue</option>
                <option value="red" #{medication.color == 'red' ? 'selected' : ''}>Red</option>
                <option value="yellow" #{medication.color == 'yellow' ? 'selected' : ''}>Yellow</option>
                <option value="green" #{medication.color == 'green' ? 'selected' : ''}>Green</option>
                <option value="pink" #{medication.color == 'pink' ? 'selected' : ''}>Pink</option>
                <option value="orange" #{medication.color == 'orange' ? 'selected' : ''}>Orange</option>
                <option value="purple" #{medication.color == 'purple' ? 'selected' : ''}>Purple</option>
                <option value="brown" #{medication.color == 'brown' ? 'selected' : ''}>Brown</option>
                <option value="clear" #{medication.color == 'clear' ? 'selected' : ''}>Clear</option>
                <option value="other" #{medication.color == 'other' ? 'selected' : ''}>Other</option>
              </select>
            </div>
            
            <div class="form-group">
              <label for="medication_shape">Pill Shape</label>
              <select id="medication_shape" name="medication[shape]">
                <option value="">Select shape...</option>
                <option value="round" #{medication.shape == 'round' ? 'selected' : ''}>Round</option>
                <option value="oval" #{medication.shape == 'oval' ? 'selected' : ''}>Oval</option>
                <option value="capsule" #{medication.shape == 'capsule' ? 'selected' : ''}>Capsule</option>
                <option value="square" #{medication.shape == 'square' ? 'selected' : ''}>Square</option>
                <option value="triangle" #{medication.shape == 'triangle' ? 'selected' : ''}>Triangle</option>
                <option value="diamond" #{medication.shape == 'diamond' ? 'selected' : ''}>Diamond</option>
                <option value="other" #{medication.shape == 'other' ? 'selected' : ''}>Other</option>
              </select>
            </div>
            
            <div class="form-actions">
              <a href="/" class="btn btn-secondary">Cancel</a>
              <input type="submit" value="Add Medication" class="btn btn-primary">
            </div>
          </form>
        </div>
      </body>
      </html>
    HTML
  end

  def generate_edit_medication_html(medication)
    errors_html = if medication.errors.any?
      error_messages = medication.errors.full_messages.map { |msg| "<li>#{msg}</li>" }.join('')
      <<~HTML
        <div class="error-messages">
          <h3>#{medication.errors.count} error(s) prohibited this medication from being saved:</h3>
          <ul>#{error_messages}</ul>
        </div>
      HTML
    else
      ''
    end

    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Edit #{h(medication.name)} - Pill Boxer</title>
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
          #{generate_base_styles}
          
          .form-container {
            max-width: 480px;
            margin: 0 auto;
            padding: 20px;
          }
          
          .form-group {
            margin-bottom: 20px;
          }
          
          .form-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #374151;
          }
          
          .form-group input,
          .form-group textarea,
          .form-group select {
            width: 100%;
            padding: 12px;
            border: 2px solid #d1d5db;
            border-radius: 8px;
            font-size: 16px;
            box-sizing: border-box;
          }
          
          .form-group input:focus,
          .form-group textarea:focus,
          .form-group select:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
          }
          
          .btn {
            display: inline-block;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            text-decoration: none;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s;
          }
          
          .btn-primary {
            background-color: #3b82f6;
            color: white;
          }
          
          .btn-primary:hover {
            background-color: #2563eb;
          }
          
          .btn-secondary {
            background-color: #f3f4f6;
            color: #374151;
            border: 2px solid #d1d5db;
          }
          
          .btn-secondary:hover {
            background-color: #e5e7eb;
          }
          
          .btn-danger {
            background-color: #dc2626;
            color: white;
          }
          
          .btn-danger:hover {
            background-color: #b91c1c;
          }
          
          .form-actions {
            display: flex;
            gap: 12px;
            margin-top: 30px;
          }
          
          .form-actions .btn {
            flex: 1;
          }
          
          .danger-zone {
            border-top: 1px solid #e5e7eb;
            margin-top: 40px;
            padding-top: 30px;
          }
          
          .danger-zone h3 {
            color: #dc2626;
            margin-bottom: 16px;
          }
          
          .error-messages {
            background-color: #fef2f2;
            border: 1px solid #fecaca;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 20px;
            color: #dc2626;
          }
          
          .error-messages ul {
            margin: 0;
            padding-left: 20px;
          }
        </style>
      </head>
      <body>
        #{generate_navigation_html(current_user)}
        
        <div class="form-container">
          <h1>Edit #{h(medication.name)}</h1>
          
          #{errors_html}
          
          <form action="/medications/#{medication.id}" method="post">
            <input type="hidden" name="_method" value="patch">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            
            <div class="form-group">
              <label for="medication_name">Medication Name *</label>
              <input type="text" id="medication_name" name="medication[name]" value="#{h(medication.name)}" required>
            </div>
            
            <div class="form-group">
              <label for="medication_dosage">Dosage *</label>
              <input type="text" id="medication_dosage" name="medication[dosage]" value="#{medication.dosage}" required>
            </div>
            
            <div class="form-group">
              <label for="medication_frequency">Frequency *</label>
              <select id="medication_frequency" name="medication[frequency]" required>
                <option value="once_daily" #{medication.frequency == 'once_daily' ? 'selected' : ''}>Once daily</option>
                <option value="twice_daily" #{medication.frequency == 'twice_daily' ? 'selected' : ''}>Twice daily</option>
                <option value="three_times_daily" #{medication.frequency == 'three_times_daily' ? 'selected' : ''}>Three times daily</option>
                <option value="four_times_daily" #{medication.frequency == 'four_times_daily' ? 'selected' : ''}>Four times daily</option>
                <option value="as_needed" #{medication.frequency == 'as_needed' ? 'selected' : ''}>As needed</option>
                <option value="other" #{medication.frequency == 'other' ? 'selected' : ''}>Other</option>
              </select>
            </div>
            
            <div class="form-group">
              <label for="medication_instructions">Instructions</label>
              <textarea id="medication_instructions" name="medication[instructions]" rows="3">#{medication.instructions}</textarea>
            </div>
            
            <div class="form-group">
              <label for="medication_color">Pill Color</label>
              <select id="medication_color" name="medication[color]">
                <option value="">Select color...</option>
                <option value="white" #{medication.color == 'white' ? 'selected' : ''}>White</option>
                <option value="blue" #{medication.color == 'blue' ? 'selected' : ''}>Blue</option>
                <option value="red" #{medication.color == 'red' ? 'selected' : ''}>Red</option>
                <option value="yellow" #{medication.color == 'yellow' ? 'selected' : ''}>Yellow</option>
                <option value="green" #{medication.color == 'green' ? 'selected' : ''}>Green</option>
                <option value="pink" #{medication.color == 'pink' ? 'selected' : ''}>Pink</option>
                <option value="orange" #{medication.color == 'orange' ? 'selected' : ''}>Orange</option>
                <option value="purple" #{medication.color == 'purple' ? 'selected' : ''}>Purple</option>
                <option value="brown" #{medication.color == 'brown' ? 'selected' : ''}>Brown</option>
                <option value="clear" #{medication.color == 'clear' ? 'selected' : ''}>Clear</option>
                <option value="other" #{medication.color == 'other' ? 'selected' : ''}>Other</option>
              </select>
            </div>
            
            <div class="form-group">
              <label for="medication_shape">Pill Shape</label>
              <select id="medication_shape" name="medication[shape]">
                <option value="">Select shape...</option>
                <option value="round" #{medication.shape == 'round' ? 'selected' : ''}>Round</option>
                <option value="oval" #{medication.shape == 'oval' ? 'selected' : ''}>Oval</option>
                <option value="capsule" #{medication.shape == 'capsule' ? 'selected' : ''}>Capsule</option>
                <option value="square" #{medication.shape == 'square' ? 'selected' : ''}>Square</option>
                <option value="triangle" #{medication.shape == 'triangle' ? 'selected' : ''}>Triangle</option>
                <option value="diamond" #{medication.shape == 'diamond' ? 'selected' : ''}>Diamond</option>
                <option value="other" #{medication.shape == 'other' ? 'selected' : ''}>Other</option>
              </select>
            </div>
            
            <div class="form-actions">
              <a href="/" class="btn btn-secondary">Cancel</a>
              <input type="submit" value="Update Medication" class="btn btn-primary">
            </div>
          </form>
          
          <div class="danger-zone">
            <h3>Danger Zone</h3>
            <p>Remove this medication from your list. This action cannot be undone.</p>
            <form action="/medications/#{medication.id}" method="post" onsubmit="return confirm('Are you sure you want to remove #{h(medication.name).gsub("'", "\\'")}'? This cannot be undone.')">
              <input type="hidden" name="_method" value="delete">
              <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
              <input type="submit" value="Remove Medication" class="btn btn-danger">
            </form>
          </div>
        </div>
      </body>
      </html>
    HTML
  end

  def generate_medications_index_html(medications)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>My Medications - Pill Boxer</title>
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
          #{generate_base_styles}
          
          .medications-container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          
          .header-section {
            background: white;
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          
          .header-section h1 {
            margin: 0;
            font-size: 24px;
            font-weight: 700;
            color: #1f2937;
          }
          
          .btn {
            display: inline-block;
            padding: 12px 24px;
            background-color: #3b82f6;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.2s;
          }
          
          .btn:hover {
            background-color: #2563eb;
            transform: translateY(-1px);
          }
          
          .btn-secondary {
            background-color: #f3f4f6;
            color: #374151;
            border: 2px solid #d1d5db;
          }
          
          .btn-secondary:hover {
            background-color: #e5e7eb;
          }
          
          .btn-small {
            padding: 8px 16px;
            font-size: 12px;
          }
          
          .medications-grid {
            display: grid;
            gap: 16px;
          }
          
          .medication-card {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            transition: transform 0.2s, box-shadow 0.2s;
          }
          
          .medication-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
          }
          
          .medication-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 16px;
          }
          
          .medication-title h3 {
            margin: 0 0 4px 0;
            font-size: 20px;
            font-weight: 600;
            color: #1f2937;
          }
          
          .medication-title p {
            margin: 0;
            font-size: 16px;
            font-weight: 500;
            color: #3b82f6;
          }
          
          .medication-details {
            margin-bottom: 20px;
          }
          
          .detail-row {
            display: flex;
            margin-bottom: 8px;
            align-items: center;
          }
          
          .detail-label {
            font-weight: 600;
            color: #374151;
            width: 100px;
            flex-shrink: 0;
          }
          
          .detail-value {
            color: #6b7280;
            flex: 1;
          }
          
          .pill-info {
            display: flex;
            gap: 16px;
            padding: 12px;
            background-color: #f8fafc;
            border-radius: 8px;
            margin-top: 12px;
          }
          
          .pill-color,
          .pill-shape {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 14px;
            color: #6b7280;
          }
          
          .color-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            border: 1px solid #d1d5db;
          }
          
          .empty-state {
            background: white;
            border-radius: 12px;
            padding: 60px 40px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
          }
          
          .empty-state .icon {
            font-size: 64px;
            margin-bottom: 24px;
            opacity: 0.5;
          }
          
          .empty-state h2 {
            margin: 0 0 12px 0;
            font-size: 24px;
            font-weight: 600;
            color: #374151;
          }
          
          .empty-state p {
            margin: 0 0 32px 0;
            font-size: 16px;
            color: #6b7280;
            line-height: 1.5;
          }

          /* Color dots */
          .color-dot.white { background-color: #ffffff; }
          .color-dot.blue { background-color: #3b82f6; }
          .color-dot.red { background-color: #ef4444; }
          .color-dot.yellow { background-color: #eab308; }
          .color-dot.green { background-color: #22c55e; }
          .color-dot.pink { background-color: #ec4899; }
          .color-dot.orange { background-color: #f97316; }
          .color-dot.purple { background-color: #8b5cf6; }
          .color-dot.brown { background-color: #a16207; }
          .color-dot.clear { background-color: #f3f4f6; }
          .color-dot.other { background-color: #6b7280; }
        </style>
      </head>
      <body>
        #{generate_navigation_html(current_user)}
        
        <div class="medications-container">
          <div class="header-section">
            <h1>My Medications (#{medications.count})</h1>
            <a href="/medications/new" class="btn">Add New Medication</a>
          </div>
          
          #{if medications.any?
            medication_cards = medications.map do |medication|
              color_info = medication.color.present? ? 
                "<div class=\"pill-color\">
                  <span class=\"color-dot #{medication.color}\"></span>
                  #{medication.color.humanize} pill
                </div>" : ''
              
              shape_info = medication.shape.present? ? 
                "<div class=\"pill-shape\">#{medication.shape.humanize} shape</div>" : ''
              
              pill_info = (color_info.present? || shape_info.present?) ? 
                "<div class=\"pill-info\">#{color_info}#{shape_info}</div>" : ''
              
              instructions_row = medication.instructions.present? ? 
                "<div class=\"detail-row\">
                  <span class=\"detail-label\">Instructions:</span>
                  <span class=\"detail-value\">#{medication.instructions}</span>
                </div>" : ''
              
              "<div class=\"medication-card\">
                <div class=\"medication-header\">
                  <div class=\"medication-title\">
                    <h3>#{h(medication.name)}</h3>
                    <p>#{medication.dosage}</p>
                  </div>
                  <div class=\"medication-actions\">
                    <a href=\"/medications/#{medication.id}/edit\" class=\"btn btn-secondary btn-small\">Edit</a>
                  </div>
                </div>
                
                <div class=\"medication-details\">
                  <div class=\"detail-row\">
                    <span class=\"detail-label\">Frequency:</span>
                    <span class=\"detail-value\">#{medication.frequency.humanize}</span>
                  </div>
                  #{instructions_row}
                  #{pill_info}
                </div>
              </div>"
            end.join('')
            
            "<div class=\"medications-grid\">#{medication_cards}</div>"
          else
            "<div class=\"empty-state\">
              <span class=\"icon\">💊</span>
              <h2>No medications yet</h2>
              <p>Start building your medication list by adding your first medication. You can include details like dosage, frequency, and visual identification.</p>
              <a href=\"/medications/new\" class=\"btn\">Add Your First Medication</a>
            </div>"
          end}
        </div>
      </body>
      </html>
    HTML
  end
end