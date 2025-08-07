# notifier.py
import smtplib
from email.message import EmailMessage
import csv
from datetime import datetime
from dotenv import load_dotenv
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import base64

from flask import render_template

load_dotenv()

def get_registered_parents(student_name):
    emails = [] 

    # Create the CSV file with headers if not present
    if not os.path.exists("parents.csv"):
        with open("parents.csv", mode="w", newline='') as f:
            writer = csv.writer(f)
            writer.writerow(["Parent Name", "Email", "Student"])

    with open("parents.csv", newline='') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if row["Student"].strip().lower() == student_name.strip().lower():
                emails.append(row["Email"])
    return emails
 
def send_email(student_name, location, parent_email, driver_name):
    sender = os.getenv("EMAIL_ADDRESS")
    password = os.getenv("EMAIL_PASSWORD")

    with open("static/saferider.png", "rb") as image_file:
        encoded_image = base64.b64encode(image_file.read()).decode('utf-8')

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"{student_name} is on the way to {location}!"
    msg["From"] = sender
    msg["To"] = parent_email

    html = f"""
        <html>
            <h2 style="color:#2E86C1;">SafeRider Notification</h2>
            <h3 style="color: black;">Dear Parent</h3>
            <p>Just to inform you that <strong>{student_name}</strong> has just been picked up and is on the way to/from <strong>{location}</strong>.</p>
            <p>Best regards,</p> 
            <br>
            <p><em>Driver: {driver_name}</em></p>
            <br>
            <p>SafeRider Team 🚐</p>
            </body>
        </html>
    """

    part = MIMEText(html, "html")
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(sender, password)
        server.sendmail(sender, parent_email, msg.as_string())


    return render_template('notify_parent.html', alert_message='Email sent successfully!')
