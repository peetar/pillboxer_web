class HomeController < ApplicationController
  before_action :require_login
  
  def index
    # Get current user's data only
    @medications = current_user.medications.where(active: true)
    @schedules = current_user.schedules
    @pillboxes = current_user.pillboxes.includes(:compartments)
    @user = current_user
    
    # Generate HTML directly without Rails views (more reliable in our setup)
    html = generate_dashboard_html_with_navigation(@medications, @schedules, @pillboxes, current_user)
    
    render html: html.html_safe
  end
  
  def test
    @medications = current_user.medications rescue []
    @schedules = current_user.schedules rescue []
    @today_logs = current_user.medication_logs rescue []
    
    render plain: "Database Test Results:
    
Medications: #{@medications.count} found
Schedules: #{@schedules.count} found  
Logs: #{@today_logs.count} found

#{@medications.any? ? "Sample medication: #{@medications.first.name}" : "No medications yet"}"
  end
  
  private
  
  def check_database_status
    return "Connected - #{Medication.count} medications, #{Schedule.count} schedules"
  rescue => e
    return "Error: #{e.message}"
  end
  
  def build_safe_schedule
    # Simple version without complex joins for now
    %w[morning afternoon evening bedtime].map do |time_period|
      {
        time: time_period,
        medications: [],
        count: 0
      }
    end
  end
  
  private
  
  def build_todays_medications
    begin
      # Get medications scheduled for today grouped by time of day
      %w[morning afternoon evening bedtime].map do |time_period|
        schedule_medications = ScheduleMedication.joins(:schedule, :medication)
                                               .where(schedules: { active: true })
                                               .where(medications: { active: true })
                                               .where(time_of_day: time_period)
                                               .includes(:medication, :schedule)
        
        {
          time: time_period,
          medications: schedule_medications,
          count: schedule_medications.sum(:quantity)
        }
      end
    rescue => e
      # If there's any error, return empty data
      Rails.logger.error "Error in build_todays_medications: #{e.message}"
      %w[morning afternoon evening bedtime].map do |time_period|
        {
          time: time_period,
          medications: [],
          count: 0
        }
      end
    end
  end
  
  def generate_dashboard_html(medications, schedules, user)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Pill Boxer - #{user.name}'s Dashboard</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
          body { font-family: system-ui, -apple-system, sans-serif; margin: 20px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; }
          .header { background: #007AFF; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
          .header img { border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.2); }
          .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 16px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .user-info { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
          .logout-btn { background: rgba(255,255,255,0.2); color: white; padding: 8px 16px; border-radius: 4px; text-decoration: none; font-size: 14px; }
          .logout-btn:hover { background: rgba(255,255,255,0.3); }
          .medication-item { padding: 12px; border-left: 4px solid #007AFF; margin: 8px 0; background: #f8f9ff; }
          .schedule-item { padding: 12px; border-left: 4px solid #34C759; margin: 8px 0; background: #f0f9f0; }
          .stats { display: flex; gap: 20px; flex-wrap: wrap; }
          .stat { flex: 1; min-width: 150px; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="user-info">
              <div style="display: flex; align-items: center; gap: 15px;">
                <img src="/pb-icon-large.png" alt="Pill Boxer" style="width: 48px; height: 48px;">
                <div>
                  <h1 style="margin: 0;">#{user.name}'s Pill Boxer</h1>
                  <p style="margin: 5px 0 0 0;">Manage your medications safely and effectively</p>
                </div>
              </div>
              <a href="/logout" class="logout-btn">Logout</a>
            </div>
          </div>
          
          <div class="card">
            <h2>System Status</h2>
            <div class="stats">
              <div class="stat">
                <h3>#{medications.count}</h3>
                <p>Total Medications</p>
              </div>
              <div class="stat">
                <h3>#{schedules.count}</h3>
                <p>Active Schedules</p>
              </div>
              <div class="stat">
                <h3>#{Time.current.strftime('%B %d')}</h3>
                <p>Today's Date</p>
              </div>
            </div>
          </div>
          
          <div class="card">
            <h2>Your Medications</h2>
            #{medications.any? ? medications.map { |med| 
              "<div class=\"medication-item\">
                <strong>#{med.name}</strong><br>
                <small>#{med.dosage} | #{med.frequency}</small>
              </div>"
            }.join('') : '<p>No medications found.</p>'}
          </div>
          
          <div class="card">
            <h2>Today's Schedule</h2>
            #{schedules.any? ? schedules.map { |schedule|
              schedule_meds = schedule.schedule_medications.map { |sm|
                "<div class=\"schedule-item\">
                  <strong>#{h(sm.medication.name)}</strong> - #{h(sm.medication.dosage)} (#{sm.quantity} pills)<br>
                  <small>Take at: #{sm.time_of_day}</small>
                </div>"
              }.join('')
              "<h3>#{schedule.name}</h3>#{schedule_meds}"
            }.join('') : '<p>No schedules configured.</p>'}
          </div>
        </div>
      </body>
      </html>
    HTML
  end

  def generate_dashboard_html_with_navigation(medications, schedules, pillboxes, user)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Dashboard - Pill Boxer</title>
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
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
          
          .nav-link:hover,
          .nav-link.active {
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
          
          /* Dashboard Styles */
          .dashboard-container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          
          .welcome-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 16px;
            margin-bottom: 30px;
            text-align: center;
          }
          
          .welcome-section h1 {
            margin: 0 0 10px 0;
            font-size: 28px;
            font-weight: 700;
          }
          
          .welcome-section p {
            margin: 0;
            opacity: 0.9;
            font-size: 16px;
          }
          
          .quick-actions {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
          }
          
          .action-card {
            background: white;
            border-radius: 12px;
            padding: 24px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            transition: transform 0.2s, box-shadow 0.2s;
          }
          
          .action-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
          }
          
          .action-card .icon {
            font-size: 48px;
            margin-bottom: 16px;
            display: block;
          }
          
          .action-card h3 {
            margin: 0 0 12px 0;
            font-size: 18px;
            font-weight: 600;
            color: #1f2937;
          }
          
          .action-card p {
            margin: 0 0 20px 0;
            color: #6b7280;
            font-size: 14px;
            line-height: 1.5;
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
            transition: background-color 0.2s;
          }
          
          .btn:hover {
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
          
          .btn-small {
            padding: 6px 12px;
            font-size: 12px;
            border-radius: 6px;
          }
          
          .medications-section {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
          }
          
          .medications-section h2 {
            margin: 0 0 20px 0;
            font-size: 20px;
            font-weight: 600;
            color: #1f2937;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          
          .medication-list {
            display: grid;
            gap: 16px;
          }
          
          .medication-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 16px;
            background-color: #ffffff;
            border-radius: 12px;
            border-left: 4px solid #3b82f6;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
            transition: all 0.2s ease;
            cursor: pointer;
          }
          
          .medication-item:hover {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            transform: translateY(-2px);
          }
          
          .medication-info h4 {
            margin: 0 0 4px 0;
            font-weight: 600;
            color: #1f2937;
            font-size: 18px;
          }
          
          .medication-info p {
            margin: 0;
            font-size: 14px;
            color: #6b7280;
          }
          
          .medication-actions {
            display: flex;
            gap: 8px;
          }
          
          .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: #6b7280;
          }
          
          .empty-state .icon {
            font-size: 64px;
            margin-bottom: 16px;
            opacity: 0.5;
          }
          
          .empty-state h3 {
            margin: 0 0 8px 0;
            font-size: 18px;
            color: #374151;
          }
          
          .empty-state p {
            margin: 0 0 24px 0;
            font-size: 14px;
          }

          /* Mobile responsive */
          @media (max-width: 768px) {
            .navbar-container {
              padding: 12px 16px;
              flex-direction: column;
              gap: 16px;
            }
            
            .navbar-nav {
              width: 100%;
              justify-content: space-between;
            }
            
            .navbar-user {
              border-left: none;
              padding-left: 0;
              gap: 12px;
            }
            
            .user-name {
              font-size: 13px;
            }
            
            .dashboard-container {
              padding: 16px;
            }
            
            .welcome-section {
              padding: 24px 20px;
            }
            
            .welcome-section h1 {
              font-size: 24px;
            }
            
            .quick-actions {
              grid-template-columns: 1fr;
            }
            
            .medications-section h2 {
              flex-direction: column;
              gap: 16px;
              align-items: stretch;
            }
            
            .medication-item {
              flex-direction: column;
              align-items: stretch;
              gap: 12px;
            }
            
            .medication-actions {
              justify-content: center;
            }
          }
        </style>
      </head>
      <body>
        <!-- Navigation Bar -->
        <nav class="navbar">
          <div class="navbar-container">
            <div class="navbar-brand">
              <a href="/"><img src="/pb-icon-large.png" alt="Pill Boxer" class="brand-icon"> Pill Boxer</a>
            </div>
            
            <div class="navbar-nav">
              <a href="/" class="nav-link active">Home</a>
              <a href="/medications" class="nav-link">Medications</a>
              <a href="/pillboxes" class="nav-link">Pill Boxes</a>
              
              <div class="navbar-user">
                <span class="user-name"> #{user.name}</span>
                <a href="/logout" class="logout-link">Logout</a>
              </div>
            </div>
          </div>
        </nav>
        
        <!-- Dashboard Content -->
        <div class="dashboard-container">
          <div class="welcome-section">
            <h1>Welcome back, #{user.name}! </h1>
            <p>Ready to manage your medications today?</p>
          </div>
          
          #{if pillboxes.any?
            needs_refill_count = pillboxes.count(&:needs_refill?)
            if needs_refill_count > 0
              "<div style=\"background: linear-gradient(135deg, #fee2e2 0%, #fef2f2 100%); border: 2px solid #ef4444; border-radius: 12px; padding: 20px; margin-bottom: 20px; box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);\">
                <div style=\"display: flex; align-items: center; gap: 16px;\">
                  <span style=\"font-size: 48px;\">⚠️</span>
                  <div style=\"flex: 1;\">
                    <h3 style=\"margin: 0 0 8px 0; color: #991b1b; font-size: 20px;\">
                      #{needs_refill_count} Pill Box#{needs_refill_count == 1 ? '' : 'es'} Need#{needs_refill_count == 1 ? 's' : ''} Refilling
                    </h3>
                    <p style=\"margin: 0; color: #7f1d1d; font-size: 14px;\">
                      It's been 7+ days since you last filled #{needs_refill_count == 1 ? 'this pill box' : 'these pill boxes'}. Click 'Fill Now' below to mark #{needs_refill_count == 1 ? 'it' : 'them'} as filled.
                    </p>
                  </div>
                </div>
              </div>"
            else
              ""
            end
          else
            ""
          end}
          
          <div class="medications-section" style="margin-bottom: 20px;">
            <h2>
              Your Pill Boxes
              <a href="/pillboxes/new" class="btn btn-small">Create New</a>
            </h2>
            
            #{if pillboxes.any?
              pillbox_list = pillboxes.map do |pillbox|
                box_type_badge = pillbox.daily? ? 
                  "<span style=\"background: #3b82f6; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;\">Daily</span>" :
                  "<span style=\"background: #10b981; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;\">Weekly</span>"
                
                fill_status = if pillbox.last_filled_at
                  days_ago = pillbox.days_since_filled
                  if days_ago == 0
                    "Filled today"
                  elsif days_ago == 1
                    "Filled yesterday"
                  else
                    "Filled #{days_ago} days ago"
                  end
                else
                  "Never filled"
                end
                
                needs_refill_class = pillbox.needs_refill? ? "color: #ef4444;" : "color: #10b981;"
                refill_badge = pillbox.needs_refill? ? 
                  "<span style=\"background: #fee2e2; color: #991b1b; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; margin-left: 8px;\">⚠️ Needs Refill</span>" : ""
                
                pill_icon = pillbox.daily? ? "💊" : "📦"
                border_color = pillbox.needs_refill? ? '#ef4444' : (pillbox.daily? ? '#3b82f6' : '#10b981')
                bg_color = pillbox.needs_refill? ? '#fef2f2' : '#ffffff'
                
                "<div class=\"medication-item\" style=\"border-left: 4px solid #{border_color}; background: #{bg_color}; position: relative; overflow: hidden;\">
                  <div style=\"position: absolute; top: 12px; right: 12px; font-size: 48px; opacity: 0.05;\">#{pill_icon}</div>
                  <div class=\"medication-info\" style=\"position: relative; z-index: 1;\">
                    <div style=\"display: flex; align-items: center; gap: 12px; margin-bottom: 8px; flex-wrap: wrap;\">
                      <span style=\"font-size: 24px;\">#{pill_icon}</span>
                      <h4 style=\"margin: 0;\">#{h(pillbox.name)}</h4>
                      #{box_type_badge}
                      #{refill_badge}
                    </div>
                    <p style=\"margin: 4px 0; color: #6b7280; font-size: 14px;\">
                      <strong>#{pillbox.compartments.count}</strong> compartments • <strong>#{pillbox.total_medications}</strong> medications
                    </p>
                    <p style=\"margin: 4px 0; #{needs_refill_class} font-size: 13px; font-weight: 500; display: flex; align-items: center; gap: 6px;\">
                      <span style=\"font-size: 16px;\">#{pillbox.needs_refill? ? '🔴' : '🟢'}</span>
                      #{fill_status}
                    </p>
                  </div>
                  <div class=\"medication-actions\" style=\"gap: 8px; position: relative; z-index: 1;\">
                    #{if pillbox.needs_refill?
                      "<a href='/pillboxes/#{pillbox.id}/fill' class='btn btn-small' style='background: #10b981; box-shadow: 0 2px 4px rgba(16, 185, 129, 0.3);'>Fill Now</a>"
                    else
                      "<a href='/pillboxes/#{pillbox.id}/fill' class='btn btn-small' style='background: #10b981;'>Fill Pill Box</a>"
                    end}
                    <a href='/pillboxes/#{pillbox.id}' class='btn btn-small'>View</a>
                    <a href='/pillboxes/#{pillbox.id}/edit' class='btn btn-small btn-secondary'>Edit</a>
                  </div>
                </div>"
              end.join('')
              
              "<div class=\"medication-list\">#{pillbox_list}</div>"
            else
              "<div class=\"empty-state\">
                <span class=\"icon\">📦</span>
                <h3>No pill boxes yet</h3>
                <p>Create your first virtual pill box to organize your medications</p>
                <a href=\"/pillboxes/new\" class=\"btn\">Create Your First Pill Box</a>
              </div>"
            end}
          </div>
          
          <div class="quick-actions">
            <div class="action-card">
              <span class="icon">💊</span>
              <h3>Add Medication</h3>
              <p>Add a new medication to your daily routine</p>
              <a href="/medications/new" class="btn">Add New</a>
            </div>
            
            <div class="action-card">
              <span class="icon">📦</span>
              <h3>Create Pill Box</h3>
              <p>Set up a new virtual pill box</p>
              <a href="/pillboxes/new" class="btn">Create Box</a>
            </div>
            
            <div class="action-card">
              <span class="icon">📋</span>
              <h3>View Medications</h3>
              <p>See your complete medication list</p>
              <a href="/medications" class="btn btn-secondary">View List</a>
            </div>
          </div>
          
          <div class="medications-section">
            <h2>
              Your Medications
              <a href="/medications/new" class="btn btn-small">Add New</a>
            </h2>
            
            #{if medications.any?
              medication_list = medications.limit(5).map do |medication|
                "<div class=\"medication-item\">
                  <div class=\"medication-info\">
                    <h4>#{h(medication.name)}</h4>
                    <p>#{medication.dosage} • #{medication.frequency.humanize}#{medication.instructions.present? ? " • #{medication.instructions}" : ''}</p>
                  </div>
                  <div class=\"medication-actions\">
                    <a href=\"/medications/#{medication.id}/edit\" class=\"btn btn-small btn-secondary\">Edit</a>
                  </div>
                </div>"
              end.join('')
              
              view_all = medications.count > 5 ? 
                "<div style=\"text-align: center; margin-top: 16px;\">
                  <a href=\"/medications\" class=\"btn btn-secondary\">View All #{medications.count} Medications →</a>
                </div>" : ''
              
              "<div class=\"medication-list\">#{medication_list}#{view_all}</div>"
            else
              "<div class=\"empty-state\">
                <span class=\"icon\">💊</span>
                <h3>No medications yet</h3>
                <p>Get started by adding your first medication</p>
                <a href=\"/medications/new\" class=\"btn\">Add Your First Medication</a>
              </div>"
            end}
          </div>
        </div>
      </body>
      </html>
    HTML
  end
end