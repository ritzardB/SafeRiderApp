from flask import Flask, render_template, request, redirect, session, url_for, flash
from notifier import send_email
import os
import csv
import uuid
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from datetime import datetime
from dotenv import load_dotenv 
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from io import BytesIO
from flask import send_file
from functools import wraps
from flask import redirect, url_for, flash, session
import re

DRIVER_DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "drivers.csv")
PARENTS_DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "parents.csv")
HISTORY_DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "history.csv")
STUDENT_DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "student.csv")  
DEFAULT_PROFILE_PIC = os.path.join("https://lottie.host/b90b26ac-aad0-4d57-8ea1-411e5e821abe/rqqTKs2hil.lottie")

load_dotenv() 
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME")
ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH")
app = Flask(__name__)
app.secret_key = os.getenv("SECRETE_KEY", "default-key-if-missing")

# Set upload folder path
UPLOAD_FOLDER = os.path.join("static", "uploads")
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# Ensure the folder exists at startup
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def generate_unique_id(): 
    return str(uuid.uuid4()) #create a unique driver's ID 

@app.route("/")
def home():
    return render_template("index.html")


import csv

def load_admins_from_csv():
    admins = []
    with open(os.path.join("data", "admins.csv"), newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            admins.append({
                "username": row["username"],
                "password": row["password"]
            })
    return admins

def load_parents_from_csv(filepath):
    with open(filepath, newline='') as f:
        return list(csv.DictReader(f))
    
    
def load_students_from_csv(filepath):
    with open(filepath, newline='') as f:
        return list(csv.DictReader(f))
    

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if "admin" not in session:
            flash("Admin login required.")
            return redirect(url_for("admin_login"))
        return f(*args, **kwargs)
    return decorated_function

def load_drivers_from_csv(path):
    drivers = []

    try:
        with open(path, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Strip whitespace and normalize keys/values
                cleaned = { (k or "").strip(): (v or "").strip() for k, v in row.items() }

                # Normalize assigned_students into a list
                if "assigned_students" in cleaned:
                    cleaned["assigned_students"] = [
                        s.strip() for s in cleaned["assigned_students"].split(",") if s.strip()
                    ]
                else:
                    cleaned["assigned_students"] = []

                drivers.append(cleaned)
    except FileNotFoundError:
        print(f"[load_drivers_from_csv] File not found: {path}")
    except Exception as e:
        print(f"[load_drivers_from_csv] Error: {e}")

    return drivers

def assign_student_ids(csv_path='data/students.csv'):
    updated_rows = []
    with open(csv_path, newline='') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            row["student_id"] = f"stu{1000 + i}"
            updated_rows.append(row)

    fieldnames = ['student_id'] + list(reader.fieldnames)
    with open(csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(updated_rows)

assign_student_ids(STUDENT_DATA_PATH)


def load_all_students(STUDENT_DATA_PATH):
    # Example loading from CSV
    students = []
    with open(STUDENT_DATA_PATH, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            students.append(row["student_name"])
    return students

@app.after_request
def add_header(response):
    response.headers["Service-Worker-Allowed"] = "/"
    return response



#-----------------------
# Validate email address 
#-----------------------
def is_valid_email(email):
    # Basic regex for email validation
    regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return re.match(regex, email) is not None   


#-----------------------
# ADMIN LOGIN 
#----------------------- 
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "supersecret123")

@app.route("/admin-login", methods=["GET", "POST"])
def admin_login():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")

        # print("Login Attempt:", username, password)
        # print("From ENV:", ADMIN_USERNAME, ADMIN_PASSWORD_HASH)
        # print("Password Check:", check_password_hash(ADMIN_PASSWORD_HASH, password))

        if username == ADMIN_USERNAME and check_password_hash(ADMIN_PASSWORD_HASH, password):
            session["admin"] = username
            flash("Admin login successful.")
            return redirect(url_for("admin_dashboard"))
        else:
            flash("Invalid admin credentials.")
            return redirect(url_for("admin_login"))
    

    return render_template("admin_login.html")

#------------------------
# Success Registration
#------------------------
@app.route("/registration-success")
def registration_success():
    return render_template("registration_success.html")


#------------------------
# ADMIN DASHBOARD
#------------------------
@app.route("/admin-dashboard")
def admin_dashboard():
    if not session.get("admin"):
        flash("You must be logged in as admin.")
        return redirect(url_for("admin_login"))

    drivers = load_drivers_from_csv(DRIVER_DATA_PATH)
    
    students = []
    if os.path.exists(STUDENT_DATA_PATH):
        with open(STUDENT_DATA_PATH, newline="") as f:
            students = list(csv.DictReader(f))

    history = []
    if os.path.exists(HISTORY_DATA_PATH):
        with open(HISTORY_DATA_PATH, newline="") as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) >= 4:
                    history.append({
                        "timestamp": row[0],
                        "student": row[1],
                        "location": row[2],
                        "driver": row[3]
                    })

    return render_template(
        "admin_dashboard.html",
        drivers=drivers,
        students=students,
        history=history
    )

#----------------------- 
# ADMIN LOGOUT
#----------------------- 
@app.route("/admin-logout")
def admin_logout():
    session.pop("admin", None)
    flash("Logged out as admin.")
    return redirect(url_for("home"))


#-----------------------
# Save and Uploads
#-----------------------
@app.route("/upload-photo", methods=["POST"])
def upload_photo():
    if request.method == "POST":
        if "photo" not in request.files:
            flash("No photo part in the form.")
            return redirect(request.url)

        photo = request.files["photo"]

        if photo.filename == "":
            flash("No selected file.")
            return redirect(request.url)

        if "user_name" not in session: 
            flash("No selected files.")
            return redirect(request.referrer)

        # Secure the filename
        filename = secure_filename(photo.filename)

        # Save the photo to static/uploads
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        photo.save(filepath)

        #Save photo path relative to "static"
        photo_url = f"/static/uploads/{filename}"

        # Update driver photo URL in your CSV or session 
        user_name = session["user_name"]
        update_driver_photo(user_name, photo_url)

        flash("Photo uploaded successfully!")
        return redirect(url_for("driver_profile"))  # Or wherever you want to go

    return render_template("driver_profile.html")

def update_driver_photo(user_name, photo_url):
    updated = False
    drivers = load_drivers_from_csv(DRIVER_DATA_PATH)
    for driver in drivers:
        if driver["user_name"] == user_name:
            driver["photo_url"] = photo_url
            updated = True
            break
    if updated:
        with open(DRIVER_DATA_PATH, "w", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=drivers[0].keys())
            writer.writeheader()
            writer.writerows(drivers)



# ----------------------
# Driver Registration 
# ----------------------
@app.route("/register", methods=["GET", "POST"]) 
def driver_register(): 
    all_students = load_all_students(STUDENT_DATA_PATH)
    if request.method == "POST":
        user_id = generate_unique_id()
        user_name = request.form.get("user_name")
        name = request.form.get("name")
        alias = request.form.get("alias")
        email = request.form.get("email", "").strip()
        password = request.form.get("password")
        phone = request.form.get("phone")
        vehicle = request.form.get("vehicle")
        license_plate = request.form.get("license_plate")
        assigned_students = request.form.getlist("assigned_students")
        photo_url = ""

        hashed_password = generate_password_hash(password)

        with open(DRIVER_DATA_PATH, "a", newline="") as f: 
            writer = csv.writer(f)
            writer.writerow((
                user_id,
                user_name,
                name,
                alias,
                email,
                hashed_password,
                phone,
                vehicle,
                license_plate,
                ",".join(assigned_students),
                photo_url
            ))
            
        flash("Driver registration successful! Please log in.")
        return redirect(url_for("driver_login")) 
    
    return render_template("driver_register.html", students=all_students) 

 
# --------------------
# Save Driver Profile
# --------------------
@app.route("/save-profile", methods=["POST"])
def save_profile():
    # Handle form fields like request.form["name"], etc.
    return redirect(url_for("driver_profile"))


# --------------------
# Driver Profile Page
# --------------------
@app.route("/profile")
def driver_profile():
    if "user_name" not in session:
        return redirect(url_for("driver_login"))
    
    user_name = session["user_name"]
    driver_id = session.get('user_id')

    drivers = load_drivers_from_csv(DRIVER_DATA_PATH)

    # Find the driver by user_id (not email anymore)
    driver = next((d for d in drivers if d.get("user_name") == user_name), None)

    if not driver:
        flash("Driver not found.")
        return redirect(url_for("driver_login"))
    
    # Get assigned students info
    assigned_students = get_assigned_students(driver_id)

    return render_template(
        "driver_profile.html",
        driver=driver,
        assigned_students=assigned_students
    )

def get_assigned_students(driver_id):
    assigned_names = []

    with open(DRIVER_DATA_PATH, newline="") as f:
        for row in csv.DictReader(f):
            if row["user_id"] == driver_id:
                assigned = row.get("assigned_students", "")
                assigned_names = [s.strip() for s in assigned.split("|") if s.strip()]
                break

    students = []
    with open(STUDENT_DATA_PATH, newline="") as f:
        for row in csv.DictReader(f):
            if row["student_name"] in assigned_names:
                students.append({
                    "name": row["student_name"],
                    "grade": row["grade"],
                    "section": row["section"],
                    "school": row["school"]
                })
    return students


# --------------------
# Driver Login Page
# --------------------
@app.route("/login", methods=["GET", "POST"])
def driver_login():
    if request.method == "POST":
        user_name = request.form.get("user_name")
        password = request.form.get("password")

        drivers = load_drivers_from_csv(DRIVER_DATA_PATH)

        for d in drivers:
            if d["user_name"].strip() == user_name.strip():
                stored_password = d["password"].strip()

                # Handle both hashed and plain passwords
                if stored_password.startswith("scrypt:"):
                    if check_password_hash(stored_password, password):
                        session["driver_id"] = d["user_id"]  # ✅ store user_id
                        session["user_name"] = d["user_name"]
                        session["name"] = d["name"]  # Make sure this line exists
                        flash("Login successful.")
                        return redirect(url_for("dashboard"))
                else:
                    if stored_password == password:
                        session.clear()
                        session["user_name"] = d["user_name"]  # ✅ store user_id
                        session["driver_id"] = d["user_id"] 
                        session["name"] = d["name"]  # Make sure this line exists   
                        flash("Login successful.")
                        return redirect(url_for("dashboard"))

        flash("Invalid email or password.")
        return redirect(url_for("driver_login"))

    return render_template("driver_login.html")

# Your CSV loading function
def load_drivers_from_csv(DRIVER_DATA_PATH):
    with open(DRIVER_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        data = []

        for row in reader:
            print("Row before processing:", row)  # Debugging aid
            cleaned = {(k or "").strip(): (v or "").strip() for k, v in row.items()}
            print("Cleaned row:", cleaned)
            data.append(cleaned)

        return data


# --------------------
# Driver Dashboard
# --------------------
@app.route("/dashboard")
def dashboard():
    if "user_name" not in session:
        return redirect(url_for("driver_login"))

    user_name = session["user_name"]
    driver_id = session.get("driver_id")
    drivers = load_drivers_from_csv(DRIVER_DATA_PATH)

    # Find the logged-in driver
    driver = next((d for d in drivers if d["user_name"].strip() == user_name.strip()), None)
    if not driver:
        flash("Driver not found.")
        return redirect(url_for("driver_login"))
    
    # 🔥 Load assigned students for this driver
    assigned_students = get_students_for_driver(driver_id)

    return render_template(
        "driver_dashboard.html",
        driver=driver,
        assigned_students=assigned_students
    )



# --------------------
# Assign Students
# --------------------
@app.route("/assign", methods=["GET", "POST"])
def assign_students():
    # Load all drivers
    drivers = []
    with open(DRIVER_DATA_PATH, mode="r") as f:
        reader = csv.reader(f)
        for row in reader:
            drivers.append(row)

    if request.method == "POST":
        driver_email = request.form["driver_email"]
        student_list = request.form["students"]

        updated_drivers = []
        for row in drivers:
            if row[1] == driver_email:
                row[5] = student_list.strip()
            updated_drivers.append(row)

        with open(DRIVER_DATA_PATH, mode="w", newline="") as f:
            writer = csv.writer(f)
            writer.writerows(updated_drivers)

        flash("Students assigned successfully.")
        return redirect(url_for("assign_students"))

    return render_template("assign_students.html", drivers=drivers)

# --------------------
# View Students
# --------------------
@app.route("/students")
def view_students():
    student = []
    if os.path.exists(STUDENT_DATA_PATH):
        with open(STUDENT_DATA_PATH, newline='') as f:
            reader = csv.reader(f)
            students = list(reader)
    return render_template("students_profile.html", students=students)


@app.route("/student/")
def student_redirect():
    return redirect(url_for("view_children"))  # or 404


# --------------------
# Parent Notification Form
# --------------------
@app.route("/notify", methods=["GET", "POST"])
def notify_parent():
    if "user_name" not in session:
        return redirect(url_for("driver_login"))

    driver_id = session.get("driver_id")

    # 💡 Deduplicate parents.csv before processing
    def remove_duplicate_parents():
        unique_entries = {}
        cleaned_rows = []

        with open(PARENTS_DATA_PATH, newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                key = (row["student_name"].strip(), row["email"].strip().lower())
                if key not in unique_entries:
                    unique_entries[key] = row
                    cleaned_rows.append(row)

        with open(PARENTS_DATA_PATH, "w", newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=reader.fieldnames)
            writer.writeheader()
            writer.writerows(cleaned_rows)

    remove_duplicate_parents()

    # 🚸 Now load cleaned student list
    students = get_students_for_driver(driver_id)

    # 👤 Get full driver's name
    drivers = load_drivers_from_csv(DRIVER_DATA_PATH)
    driver_info = next((d for d in drivers if d.get("user_id") == driver_id), None)
    driver_name = driver_info.get("name") if driver_info else "Unknown Driver"  

    if request.method == "POST": 
        student = request.form.get("student")
        location = request.form.get("location")
        driver = driver_name

        # Corrected line
        student_obj = next((s for s in students if s["name"] == student), None)
        parent_email = student_obj.get("parent_email") if student_obj else None 

        if not parent_email: 
            return "Parent's email not found for student", 400
        
        send_email(student, location, parent_email, driver)

        with open(HISTORY_DATA_PATH, "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"), 
                student,
                location,
                driver_name
            ])

        flash("Notification sent successfully!")
        return redirect(url_for("notify_parent"))
    
    return render_template("notify_parent.html", students=students, driver=driver_name)

# --------------------
# Parent Management
# --------------------
@app.route("/parent_login", methods=["GET", "POST"])
def parent_login():
    if request.method == "POST":
        input_username = request.form.get("parent_username")
        input_password = request.form.get("parent_password")

        with open(PARENTS_DATA_PATH, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["parent_username"] == input_username:
                    if check_password_hash(row["parent_password"], input_password):
                        session["parent_email"] = row["email"]
                        session["parent_name"] = row["parent_name"]
                        session["parent_username"] = row["parent_username"]
                        session["parent_phone"] = row["phone"]
                        return redirect(url_for("parent_profile"))
                    else:
                        flash("Incorrect password.", "danger")
                        return redirect(url_for("parent_login"))

        flash("Username not found.", "danger")
    return render_template("parent_login.html")


# --------------------
# Parent Registration
# --------------------
@app.route("/parent-register", methods=["GET", "POST"])
def parent_register():
    if request.method == "POST":
        # Parent info
        parent_username = request.form.get("parent_username", "").strip().lower()

        if is_username_taken(parent_username):
            flash("Username is already taken. Please choose a different one.", "danger")
            return redirect(url_for("parent_register"))
        
        parent_password = generate_password_hash(request.form.get("parent_password"))
        parent_name = request.form.get("parent_name")
        home_address = request.form.get("home_address", "").strip() 
        email = request.form.get("email", "").strip()
        phone = request.form.get("phone")

        # Student info
        student_name = request.form.get("student_name")
        grade = request.form.get("grade")
        section = request.form.get("section")
        school = request.form.get("school")
        driver_nickname = request.form.get("driver_alias", "").strip().lower() 

        drivers = load_drivers_from_csv(DRIVER_DATA_PATH)

        matched_driver = next(
            (d for d in drivers 
            if driver_nickname in (
                d.get("alias", "").strip().lower(),
                d.get("name", "").strip().lower()
            )
            ),
            None 
        )

        if not matched_driver:
            flash("Registration Unsuccessful! We couldn't find a driver by that name or nickname. Please try again or contact the driver himself")
            return redirect(url_for("parent_register"))

        # Assign here after the check
        assigned_driver_id = matched_driver["user_id"]


        # Save student info
        # Use the CSV header-writing safe function I mentioned before or write directly with header check
        save_student(parent_name, student_name, phone, email, grade, section, school)

        parent_id = str(uuid.uuid4())  # Generate a unique parent ID

        # Save parent info into csv file
        save_parent(
            parent_id,
            parent_username,
            parent_password,
            parent_name,
            home_address,
            email,
            phone,
            student_name,
            school,
            assigned_driver_id
        )

        # Assign student to driver in drivers.csv
        assign_student_to_driver(assigned_driver_id, student_name)

        flash("Parent and student registered successfully!")
        return redirect(url_for("registration_success"))

    # GET method: render the registration form
    return render_template("parent_register.html")

def save_student(parent_name, student_name, phone, email, grade, section, school):
    file_exists = os.path.isfile(STUDENT_DATA_PATH)
    write_header = not file_exists or os.path.getsize(STUDENT_DATA_PATH) == 0

    with open(STUDENT_DATA_PATH, "a", newline="") as f:
        fieldnames = ["parent_name", "student_name", "phone", "email", "grade", "section", "school"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if write_header:
            writer.writeheader()
        writer.writerow({
            "parent_name": parent_name,
            "student_name": student_name,
            "phone": phone,
            "email": email,
            "grade": grade,
            "section": section,
            "school": school
        })

def save_parent(parent_id, 
                parent_username, 
                parent_password, 
                parent_name, 
                home_address, 
                email, phone, 
                student_name, 
                school, 
                assigned_driver_id
            ):
    file_exists = os.path.isfile(PARENTS_DATA_PATH)
    write_header = not file_exists or os.path.getsize(PARENTS_DATA_PATH) == 0

    with open(PARENTS_DATA_PATH, "a", newline="") as f:
        fieldnames = [
            "parent_id", "parent_username", "parent_password", "parent_name", "home_address",
            "email", "phone", "student_name", "school", "assigned_driver_id"
        ]

        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if write_header:
            writer.writeheader()
        writer.writerow({
            "parent_id": parent_id,
            "parent_username": parent_username,
            "parent_password": parent_password,
            "parent_name": parent_name,
            "home_address": home_address,
            "email": email,
            "phone": phone,
            "student_name": student_name,
            "school": school,
            "assigned_driver_id": assigned_driver_id
        })

def update_parent_photo(email, photo_url):
    updated = False
    parents = load_parents_from_csv(PARENTS_DATA_PATH)
    for parent in parents:
        if parent["email"].strip().lower() == email.strip().lower():
            parent["photo_url"] = photo_url
            updated = True
            break
    if updated:
        with open(PARENTS_DATA_PATH, "w", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=parents[0].keys())
            writer.writeheader()
            writer.writerows(parents)


# ---------- Assign Students to the Driver ---------------------

def assign_student_to_driver(driver_id, student_name):
    updated_rows = []
    with open(DRIVER_DATA_PATH, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["user_id"] == driver_id:
                existing = row.get("assigned_students", "").strip()
                students = existing.split("|") if existing else []
                students.append(student_name)
                row["assigned_students"] = "|".join(students)
            updated_rows.append(row)

    with open(DRIVER_DATA_PATH, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=updated_rows[0].keys())
        writer.writeheader()
        writer.writerows(updated_rows)

# ----- Get assigned students to driver --------------

def get_students_for_driver(driver_id):
    assigned = []
    with open(DRIVER_DATA_PATH, newline="") as f:
        drivers = csv.DictReader(f)
        for row in drivers:
            if row["user_id"] == driver_id:
                student_names = row.get("assigned_students", "").split("|")
                break
        else:
            return []
    
    with open(STUDENT_DATA_PATH, "r", newline="") as f:
        students = csv.DictReader(f)
        for row in students:
            if row["student_name"] in student_names:
                assigned.append({
                    "name": row["student_name"],
                    "parent_email": row.get("parent_email", ""),
                    "grade": row.get("grade", ""),
                    "section": row.get("section", ""),
                    "school": row.get("school", ""),
                    "home_address": row.get("home_address", "")
                })
    return assigned



# ---------------------
# Parent Upload photo 
# ---------------------
@app.route("/upload-parent-photo", methods=["POST"])
def upload_parent_photo():
    if "parent_email" not in session:
        flash("You must be logged in.")
        return redirect(url_for("parent_login"))

    if "photo" not in request.files:
        flash("No photo part in the form.")
        return redirect(request.referrer)

    photo = request.files["photo"]

    if photo.filename == "":
        flash("No selected file.")
        return redirect(request.referrer)

    filename = secure_filename(photo.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    photo.save(filepath)
    photo_url = f"/static/uploads/{filename}"

    # Update CSV
    email = session["parent_email"]
    updated = False
    parents = []

    with open(PARENTS_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["email"].strip().lower() == email:
                row["photo_url"] = photo_url
                updated = True
            parents.append(row)

    if updated:
        with open(PARENTS_DATA_PATH, "w", newline='') as f:
            writer = csv.DictWriter(f, fieldnames=parents[0].keys())
            writer.writeheader()
            writer.writerows(parents)

    flash("Parent photo uploaded successfully!")
    return redirect(url_for("parent_profile"))


# ---------------------
# Username validation 
# ---------------------
def is_username_taken(username):
    with open(PARENTS_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["parent_username"].strip().lower() == username.strip().lower():
                return True
    return False


#----------------------------------------------------------------------------------------------------------
# Parent Profile Page
#---------------------
@app.route("/parent_profile")
def parent_profile():
    if "parent_email" not in session:
        return redirect(url_for("parent_login"))

    parent_email = session["parent_email"].strip().lower()
    children = []

    # Initialize parent and driver info
    parent_info = {
        "parent_username": "",
        "parent_name": "",
        "home_address": "",
        "parent_phone": "",
        "parent_email": parent_email
    }
    assigned_driver_info = {
        "name": "",
        "phone": ""
    }

    # Load all drivers
    drivers = {}
    with open(DRIVER_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            drivers[row["user_id"]] = {
                "name": row.get("name", ""),
                "phone": row.get("phone", ""),
                "plate": row.get("plate_number", ""),
                "alias": row.get("alias", "")
            }

    # Find parent & children entries
    with open(PARENTS_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["email"].strip().lower() == parent_email:
                # Capture parent info from the first match
                if not parent_info["parent_name"]:
                    parent_info["parent_name"] = row.get("parent_name", "")
                    parent_info["parent_username"] = row.get("parent_username", "")
                    parent_info["parent_phone"] = row.get("phone", "")
                    parent_info["home_address"] = row.get("home_address", "")   

                # Get driver info
                driver_id = row.get("assigned_driver_id", "")
                if driver_id and driver_id in drivers:
                    assigned_driver_info["name"] = drivers[driver_id]["name"]
                    assigned_driver_info["phone"] = drivers[driver_id]["phone"]

                # Append child info
                children.append({
                    "student_name": row["student_name"],
                    "school": row["school"]
                })

    return render_template("parent_profile.html",
        default_parent="default_parent.png",
        parent_name=parent_info["parent_name"],
        parent_username=parent_info["parent_username"],
        home_address=parent_info["home_address"],
        parent_email=parent_info["parent_email"],
        parent_phone=parent_info["parent_phone"],
        assigned_driver_name=assigned_driver_info["name"],
        assigned_driver_phone=assigned_driver_info["phone"],
        children=children
    )


# --------------------
# View Notification History
# --------------------
@app.route("/history")
def history():
    driver_name = session.get("name")  # Get full name instead of username
    if not driver_name:
        flash("You must be logged in.")
        return redirect(url_for("driver_login"))
    

    history_rows = []
    try:
        with open(HISTORY_DATA_PATH, newline="") as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) >= 4:
                    if row[3] == driver_name:  # Match full name
                        history_rows.append({
                            "timestamp": row[0],
                            "student": row[1],
                            "location": row[2],
                            "driver": row[3]
                        })

    except FileNotFoundError:
        print("No logs yet.")

    print("Final history_rows:", history_rows)  # Confirm it has data
    return render_template("history.html", history=history_rows)




# --------------------
# Export Notification History as PDF
# --------------------
@app.route("/export-history")
@admin_required  # or use driver session check
def export_history_pdf():
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    elements = []
    styles = getSampleStyleSheet()

    # Title
    elements.append(Paragraph("Notification History Report", styles["Title"]))
    elements.append(Spacer(1, 12))

    # Read history
    data = [["Timestamp", "Student", "Location", "Driver"]]
    if os.path.exists(HISTORY_DATA_PATH):
        with open(HISTORY_DATA_PATH, newline="") as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) >= 4:
                    data.append(row[:4])

    table = Table(data)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.black)
    ]))

    elements.append(table)
    doc.build(elements)

    buffer.seek(0)
    return send_file(buffer, as_attachment=True, download_name="notification_history.pdf", mimetype="application/pdf")

# --------------------
# View Children/Students
# --------------------
@app.route("/view_children")
def view_children():
    parent_email = session.get("parent_email")
    children = []
    # Check if parent is logged in
    with open(STUDENT_DATA_PATH, newline="") as f: 
        reader = csv.DictReader(f)
        for row in reader:
            print("Load child", row) 
            children.append({
                "student_id": row.get("student_id") or str(uuid.uuid4())[:8],
                "student_name": row.get("student_name"), 
                "school": row.get("school"), 
                "photo_url": row.get("student_photo_url") or "/static/uploads/default_student.png"
            })
    return render_template("view_children.html", children=children)


input_path = STUDENT_DATA_PATH
output_rows = []

with open(input_path, newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if not row.get("student_id"):
            row["student_id"] = str(uuid.uuid4())[:8]
        output_rows.append(row)

with open(input_path, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=output_rows[0].keys())
    writer.writeheader()
    writer.writerows(output_rows)

print("Updated student IDs where missing.")


# --------------------
# Add Child/Student
# --------------------
@app.route("/add_child", methods=["GET", "POST"])
def add_child():
    if "parent_email" not in session:
        return redirect(url_for("parent_login"))

    if request.method == "POST":
        student_name = request.form.get("student_name")
        school = request.form.get("school")

        with open(PARENTS_DATA_PATH, "a", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "parent_id", "parent_username", "parent_password",
                "parent_name", "home_address", "email", "phone",
                "student_name", "school", "assigned_driver_id"
            ])
            parent_email = session["parent_email"]

            # Find parent details
            with open(PARENTS_DATA_PATH, newline='') as fr:
                reader = csv.DictReader(fr)
                parent_row = next((r for r in reader if r["email"].strip().lower() == parent_email), None)

            if parent_row:
                writer.writerow({
                    "parent_id": parent_row["parent_id"],
                    "parent_username": parent_row["parent_username"],
                    "parent_password": parent_row["parent_password"],
                    "parent_name": parent_row["parent_name"],
                    "home_address": parent_row["home_address"],
                    "email": parent_row["email"],
                    "phone": parent_row["phone"],
                    "student_name": student_name,
                    "school": school,
                    "assigned_driver_id": parent_row["assigned_driver_id"]
                })
                flash("Child/student added successfully!")
                return redirect(url_for("view_children"))

        flash("Something went wrong while adding child.")
    return render_template("add_child.html")

# --------------------
# Update Profile
#- --------------------
@app.route("/update_profile", methods=["GET", "POST"])
def update_profile():
    if "parent_email" not in session:
        return redirect(url_for("parent_login"))

    email = session["parent_email"]
    updated_rows = []

    if request.method == "POST":
        updated_name = request.form.get("parent_name")
        updated_phone = request.form.get("phone")

        with open(PARENTS_DATA_PATH, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["email"].strip().lower() == email:
                    row["parent_name"] = updated_name
                    row["home_address"] = request.form.get("home_address", "").strip()
                    row["phone"] = updated_phone
                updated_rows.append(row)

        with open(PARENTS_DATA_PATH, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=updated_rows[0].keys())
            writer.writeheader()
            writer.writerows(updated_rows)

        flash("Profile updated successfully!")
        return redirect(url_for("update_profile"))

    # Load current info
    with open(PARENTS_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        current_data = next((r for r in reader if r["email"].strip().lower() == email), None)

    return render_template("update_profile.html", parent=current_data)

# --------------------
# View Ride History
# --------------------
@app.route("/view_rides")
def view_rides():
    if "parent_email" not in session:
        return redirect(url_for("parent_login"))

    email = session["parent_email"]
    student_names = set()

    with open(STUDENT_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["parent_email"].strip().lower() == session["parent_email"]:
                student_names.add(row["student_name"].strip())


    with open(PARENTS_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["email"].strip().lower() == email:
                student_names.add(row["student_name"])

    rides = []
    with open(HISTORY_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["student"] in student_names:
                rides.append({
                    "timestamp": row["timestamp"],
                    "student": row["student"],
                    "location": row["location"],
                    "driver": row["driver"]
            })
    return render_template("view_rides.html", rides=rides)

# --------------------
# Driver Reset Password
# --------------------
from flask import flash

@app.route("/driver_reset_password", methods=["GET", "POST"])
def driver_reset_password():
    if request.method == "POST":
        email = request.form.get("email").strip().lower()
        username = request.form.get("username").strip()
        new_password = request.form.get("new_password")
        confirm_password = request.form.get("confirm_password")

        if new_password != confirm_password:
            flash("Passwords do not match.", "danger")
            return redirect(url_for("driver_reset_password"))

        updated = False
        drivers = []

        with open(DRIVER_DATA_PATH, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["email"].strip().lower() == email and row["user_name"].strip() == username:
                    row["password"] = generate_password_hash(new_password)
                    updated = True
                drivers.append(row)

        if updated:
            with open(DRIVER_DATA_PATH, "w", newline='') as f:
                writer = csv.DictWriter(f, fieldnames=drivers[0].keys())
                writer.writeheader()
                writer.writerows(drivers)

            flash("Password has been successfully reset ✅", "success")
            return redirect(url_for("driver_login"))
        else:
            flash("No matching driver found. Please check your email and username.", "warning")
            return redirect(url_for("driver_reset_password"))

    return render_template("driver_reset_password.html")


# -------------------------------------------------------------------------------------------------------------------
# Student Profile Page
# --------------------
@app.route("/student/<student_id>")
def student_profile(student_id):
    student = None
    with open(STUDENT_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['student_id'] == student_id:
                student = {
                    "id": row['student_id'],
                    "name": row['student_name'],
                    "phone": row['phone'],
                    "grade": row['grade'],
                    "group": row['section'],
                    "school": row['school'],
                    "photo_url": row['student_photo_url'] or '/static/uploads/default_student.png'
                }
                break
    if not student:
        return "Student not found", 404

    # ✅ Render the template (no redirect)
    return render_template("student_profile.html", student=student)




def get_student_by_id(student_id, csv_path='data/students.csv'):
    with open(STUDENT_DATA_PATH, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['student_id'] == student_id:
                return row
    return None

# --------------------
# Upload Student Photo
# --------------------

@app.route("/upload-student-photo", methods=["POST"])
def upload_student_photo():
    if "parent_email" not in session:
        flash("You must be logged in as a parent.")
        return redirect(url_for("parent_login"))

    parent_email = session["parent_email"]
    student_id = request.form.get("student_id") 
    student_name = request.form.get("student_name")
    photo = request.files.get("photo")

    if not student_id or not student_name or not photo or photo.filename == "":
        flash("Please select a student and a valid photo.")
        return redirect(url_for("parent_profile"))

    filename = secure_filename(f"{student_name}_{photo.filename}")
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    photo.save(filepath)
    photo_url = f"/static/uploads/{filename}"

    update_student_photo(student_id, parent_email, photo_url)
    
    flash("Student photo uploaded successfully!")
    return redirect(url_for("student_profile", student_id=student_id))



def update_student_photo(student_id, parent_email, photo_url):
    updated = False
    students = load_students_from_csv(STUDENT_DATA_PATH)
    for student in students:
        if (student["student_id"] == student_id and 
            student["parent_email"].strip().lower() == parent_email.strip().lower()):
            student["student_photo_url"] = photo_url
            updated = True
            break

    if updated:
        with open(STUDENT_DATA_PATH, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=students[0].keys())
            writer.writeheader()
            writer.writerows(students)




# --------------------
# Logout
# --------------------
@app.route("/logout")
def logout():
    session.clear()
    flash("This initiative is to ensure that your child is in good hands.")
    return redirect(url_for("home"))

# --------------------
# Run the App
# --------------------
if __name__ == "__main__":
    app.run(debug=True, host="127.0.0.1", port=5000)



