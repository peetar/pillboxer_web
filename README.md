# Pillboxer Web Application

A medication management system built with Ruby, Sinatra, and Hotwire that helps users organize their medications into pill boxes with visual representations and refill tracking.

## Features

### Medication Management
- Create, edit, and delete medications with names, dosages, and colors
- Visual color-coding for easy medication identification
- User-scoped medications for privacy and organization

### Pill Box System
- **Daily and Weekly Pill Boxes**: Organize medications by time of day or day of week
- **4-Step Creation Wizard**:
  1. Name your pill box and select type (daily/weekly)
  2. Configure compartments (up to 12 per box)
  3. Assign medications with quantities to each compartment
  4. Review and confirm your pill box setup
- **Visual Representation**: Grid layout showing compartments with color-coded pills
- **Smart Refill Tracking**: 
  - Daily boxes show refill reminder after 1 day
  - Weekly boxes show refill reminder after 7 days
  - Visual indicators on cards when refills are needed
- **Fill Wizard**: Multi-step process to mark pill boxes as filled and update last-filled timestamp

### Edit and Management
- Edit page focuses on medication management (add/remove medications with quantities)
- Compartments are static after creation to maintain pill box structure
- Delete pill boxes with confirmation
- Character limits: 15 characters for pill box names, 10 for compartment names

### Security
- XSS protection with HTML escaping for all user input
- CSRF protection on all state-changing operations
- SQL injection protection through parameterized queries
- User authentication and session management
- Password hashing with bcrypt

### User Interface
- Responsive design with Hotwire Turbo for seamless navigation
- Consistent header with pill box icon across all pages
- Auto-dismissing flash messages for user feedback
- Hover effects and visual feedback on interactive elements
- Watermark pill box icon on cards

## Project Structure

The web application follows a Rails-like structure:

- **app/controllers**: Business logic for medications, pill boxes, sessions, and users
- **app/models**: ActiveRecord models (Medication, Pillbox, Compartment, Schedule, User)
- **app/views**: ERB templates with layouts and partials
- **app/javascript**: Stimulus controllers for interactivity (auto-dismiss, etc.)
- **app/assets**: Stylesheets, images, and JavaScript files
- **config**: Application configuration, database setup, and routes
- **db**: Database migrations, schema, and seed data
- **test**: Minitest test suite with model and controller tests

## Setup Instructions

1. **Install Ruby**: Ensure you have Ruby 3.0+ installed. Download from [ruby-lang.org](https://www.ruby-lang.org/en/downloads/).

2. **Install Bundler**: 
   ```bash
   gem install bundler
   ```

3. **Install Dependencies**: 
   ```bash
   cd web
   bundle install
   ```

4. **Setup Database**:
   ```bash
   rake db:migrate
   rake db:seed  # Optional: Load sample data
   ```

## Usage

### Starting the Server

From the `web` directory:
```bash
ruby server.rb
```

Visit `http://localhost:4567` in your web browser.

### Running Tests

```bash
rake test              # Run all tests
rake test_models       # Run model tests only
rake test_pillbox      # Run pillbox tests only
rake test_compartment  # Run compartment tests only
```

### Creating Your First Pill Box

1. **Sign up/Login**: Create an account or log in
2. **Add Medications**: Navigate to Medications and add your medications with colors
3. **Create Pill Box**: Click "Pill Boxes" → "New Pill Box"
4. **Follow Wizard**:
   - Enter a name and select daily or weekly type
   - Add compartments (e.g., "Morning", "Evening" for daily)
   - Assign medications to compartments with quantities
   - Review and create
5. **Fill Your Pill Box**: Click "Fill" to mark when you've filled it
6. **Track Refills**: Cards will show when refills are needed

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request with your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.