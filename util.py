import csv
import os

DRIVERS_CSV = "data/drivers.csv"
STUDENTS_CSV = "data/students.csv"

def load_drivers_from_csv():
    drivers = []
    if os.path.exists(DRIVERS_CSV):
        with open(DRIVERS_CSV, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                drivers.append(row)
    return drivers

def load_all_students():
    students = []
    if os.path.exists(STUDENTS_CSV):
        with open(STUDENTS_CSV, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                students.append(row["name"])  # or whatever field represents student name
    return students
