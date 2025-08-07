# Copilot Instructions for SafeRiderApp

## Project Overview
- **SafeRiderApp** is a Flask web application for managing school transport safety, with roles for drivers, admins, parents, and students.
- Data is stored in CSV files under the `data/` directory (e.g., `drivers.csv`, `student.csv`, `parents.csv`).
- The app uses server-side sessions for authentication and role management.

## Key Components
- `app.py`: Main Flask app, all routes and logic are here.
- `notifier.py`: Handles email notifications (see `send_email`).
- `static/` and `templates/`: Frontend assets and Jinja2 HTML templates.
- `data/`: All persistent data (CSV files for users, students, history, etc.).

## Data Flow & Patterns
- **Driver registration/login**: Data written/read from `data/drivers.csv`. Passwords are hashed (scrypt) on registration.
- **Student assignment**: Students are assigned to drivers by updating the `assigned_students` field (pipe-separated) in `drivers.csv`.
- **Parent registration**: Registers both parent and student, assigns student to driver by nickname/alias.
- **Notification**: Drivers notify parents via email; notifications are logged in `data/history.csv`.
- **Admin**: Admin credentials are loaded from environment variables (`.env`).

## Conventions & Patterns
- All CSVs use headers; always check for header presence before writing.
- `assigned_students` in `drivers.csv` is a pipe-separated string (e.g., `Alice|Bob`).
- Use `user_id` (UUID) as the primary key for drivers.
- Passwords may be plain or scrypt-hashed; always check which before validating.
- Use `session["user_name"]` and `session["driver_id"]` for driver authentication.
- All uploads (e.g., profile photos) go to `static/uploads/`.

## Developer Workflows
- **Run locally**: `python app.py` (Flask debug mode enabled by default).
- **Dependencies**: Install with `pip install -r requirements.txt`.
- **Environment**: Set up `.env` with `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`, and `SECRETE_KEY`.
- **No formal tests**: Manual testing via browser.
- **PDF export**: Admins can export notification history as PDF (uses `reportlab`).

## Integration Points
- **Email**: Outbound email via `notifier.py` (SMTP config not shown here).
- **PDF**: Uses `reportlab` for PDF generation.
- **Environment**: Relies on `.env` for secrets and admin credentials.

## Examples
- To add a new driver field, update both the registration form and CSV handling in `app.py`.
- To change student assignment logic, edit `assign_student_to_driver` and `get_students_for_driver` in `app.py`.

## Cautions
- Do not change CSV field order without updating all read/write logic.
- Do not store sensitive data in plain text; always hash passwords.
- Always use `secure_filename` for uploads.

---

For questions about unclear data flows or edge cases, review `app.py` as the single source of truth.
