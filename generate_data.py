import os
from faker import Faker
import random
from datetime import datetime, timedelta, date

# --- Configuration (REVISED) ---
NUM_HOTELS = 20
NUM_GUESTS = 10000
NUM_JOBS = 15
NUM_ROOMS_PER_HOTEL = 50
NUM_SERVICES_PER_HOTEL = 10
NUM_DEPTS_PER_HOTEL = 5
NUM_EMPLOYEES_PER_HOTEL = 30

# Increased record counts
NUM_BOOKINGS = 100000
NUM_BOOKING_DETAILS = 120000
NUM_GUEST_SERVICES = 100000

# Expanded to 15-year range
DWH_START_DATE = date(2010, 1, 1)
DWH_END_DATE = date(2024, 12, 31)

OUTPUT_FILE = "3_insert_data.sql"

# Initialize Faker
fake = Faker()

# --- Lists to store generated Primary Keys for Foreign Key relationships ---
hotel_ids = list(range(1, NUM_HOTELS + 1))
guest_ids = list(range(1, NUM_GUESTS + 1))
job_ids = list(range(1, NUM_JOBS + 1))
room_ids = []
service_ids = []
department_ids = []
booking_ids = list(range(1, NUM_BOOKINGS + 1))
employee_ids = list(range(1, (NUM_HOTELS * NUM_EMPLOYEES_PER_HOTEL) + 1))

# --- Sets for ensuring uniqueness ---
unique_emails = set()
service_prices = {} # To store service prices for later calculation

def get_unique_email(name):
    """Generates a unique email to avoid constraint violations."""
    base_email = f"{name.replace(' ', '.').lower()}@{fake.free_email_domain()}"
    email = base_email
    counter = 1
    while email in unique_emails:
        email = f"{name.replace(' ', '.').lower()}{counter}@{fake.free_email_domain()}"
        counter += 1
    unique_emails.add(email)
    return email
    
def escape_sql_string(value):
    """Escapes single quotes and ampersands for Oracle SQL."""
    if value is None:
        return "NULL"
    return str(value).replace("'", "''").replace('&', 'and')

def generate_hotels(f):
    f.write("-- (1) Hotels\n")
    for i in hotel_ids:
        sql = f"INSERT INTO Hotel (hotel_id, email, phone, rating, city, region, state, country, postal_code) VALUES ({i}, '{get_unique_email(f'hotel.{i}')}', '{fake.phone_number()[:25]}', {round(random.uniform(3.5, 5.0), 1)}, '{escape_sql_string(fake.city())}', NULL, '{escape_sql_string(fake.state())}', '{escape_sql_string(fake.country())}', '{fake.postcode()}');\n"
        f.write(sql)
    f.write("\n")

def generate_guests(f):
    f.write("-- (2) Guests\n")
    for i in guest_ids:
        first_name = escape_sql_string(fake.first_name())
        last_name = escape_sql_string(fake.last_name())
        email = get_unique_email(f'{first_name}.{last_name}')
        sql = f"INSERT INTO Guest (guest_id, first_name, last_name, email, phone, city, region, state, country, postal_code) VALUES ({i}, '{first_name}', '{last_name}', '{email}', '{fake.phone_number()[:25]}', '{escape_sql_string(fake.city())}', NULL, '{escape_sql_string(fake.state())}', '{escape_sql_string(fake.country())}', '{fake.postcode()}');\n"
        f.write(sql)
    f.write("\n")

def generate_jobs(f):
    f.write("-- (3) Jobs\n")
    job_titles = ['General Manager', 'Front Desk Clerk', 'Concierge', 'Housekeeper', 'Executive Chef', 'Sous Chef', 'Bartender', 'Waiter/Waitress', 'Maintenance Manager', 'Security Guard', 'Hotel Accountant', 'Marketing Manager', 'Events Coordinator', 'IT Specialist', 'HR Manager']
    for i in job_ids:
        title = job_titles[i-1]
        min_sal = random.randint(30000, 50000)
        max_sal = min_sal + random.randint(10000, 30000)
        sql = f"INSERT INTO Jobs (job_id, job_title, min_salary, max_salary) VALUES ({i}, '{title}', {min_sal}, {max_sal});\n"
        f.write(sql)
    f.write("\n")

def generate_departments(f):
    f.write("-- (4) Departments\n")
    dept_names = ['Management', 'Front Office', 'Housekeeping', 'Food and Beverage', 'Maintenance']
    dept_id_counter = 1
    for hotel_id in hotel_ids:
        for dept_name in dept_names:
            department_ids.append(dept_id_counter)
            sql = f"INSERT INTO Department (department_id, department_name, hotel_id) VALUES ({dept_id_counter}, '{dept_name}', {hotel_id});\n"
            f.write(sql)
            dept_id_counter += 1
    f.write("\n")
    
def generate_rooms(f):
    f.write("-- (5) Rooms\n")
    room_types = ['Single', 'Double', 'Suite', 'Deluxe', 'Family']
    room_id_counter = 1
    for hotel_id in hotel_ids:
        for _ in range(NUM_ROOMS_PER_HOTEL):
            room_ids.append(room_id_counter)
            room_type = random.choice(room_types)
            bed_count = 1 if room_type == 'Single' else (2 if room_type in ['Double', 'Deluxe'] else random.randint(2, 4))
            price = round(random.uniform(80.0, 500.0), 2)
            sql = f"INSERT INTO Room (room_id, room_type, bed_count, price, hotel_id) VALUES ({room_id_counter}, '{room_type}', {bed_count}, {price}, {hotel_id});\n"
            f.write(sql)
            room_id_counter += 1
    f.write("\n")

# REVISED: Added service_type
def generate_services(f):
    f.write("-- (6) Services\n")
    service_definitions = {
        'Airport Shuttle': 'Transport',
        'Room Service': 'Dining',
        'Laundry Service': 'Convenience',
        'Spa Treatment': 'Wellness',
        'Gym Access': 'Recreation',
        'Valet Parking': 'Transport',
        'Conference Room Rental': 'Business',
        'Bike Rental': 'Recreation',
        'City Tour Package': 'Recreation',
        'Pet Care': 'Convenience'
    }
    service_id_counter = 1
    for hotel_id in hotel_ids:
        for name, s_type in service_definitions.items():
            service_ids.append(service_id_counter)
            price = round(random.uniform(15.0, 200.0), 2)
            service_prices[service_id_counter] = price  # Store price for later use
            desc = escape_sql_string(f"Provides convenient {name} for our valued guests.")
            sql = f"INSERT INTO Service (service_id, description, service_name, service_price, service_type, hotel_id) VALUES ({service_id_counter}, '{desc}', '{name}', {price}, '{s_type}', {hotel_id});\n"
            f.write(sql)
            service_id_counter += 1
    f.write("\n")

def generate_employees(f):
    f.write("-- (7) Employees\n")
    depts_per_hotel = len(department_ids) // len(hotel_ids)
    for i in employee_ids:
        first_name = escape_sql_string(fake.first_name())
        last_name = escape_sql_string(fake.last_name())
        email = get_unique_email(f'{first_name}.{last_name}')
        job_id = random.choice(job_ids)
        hotel_index = (i - 1) // NUM_EMPLOYEES_PER_HOTEL
        start_dept_index = hotel_index * depts_per_hotel
        end_dept_index = start_dept_index + depts_per_hotel
        dept_id = random.choice(department_ids[start_dept_index:end_dept_index])
        sql = f"INSERT INTO Employee (employee_id, first_name, last_name, email, job_id, department_id) VALUES ({i}, '{first_name}', '{last_name}', '{email}', {job_id}, {dept_id});\n"
        f.write(sql)
    f.write("\n")

def generate_bookings(f):
    f.write("-- (8) Bookings\n")
    payment_methods = ['Credit Card', 'Debit Card', 'Cash', 'Bank Transfer']
    for i in booking_ids:
        guest_id = random.choice(guest_ids)
        payment_method = random.choice(payment_methods)
        payment_date = fake.date_between_dates(date_start=DWH_START_DATE, date_end=DWH_END_DATE)
        total_price = round(random.uniform(100.0, 2500.0), 2)
        sql = f"INSERT INTO Booking (booking_id, total_price, payment_method, payment_date, guest_id) VALUES ({i}, {total_price}, '{payment_method}', TO_DATE('{payment_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {guest_id});\n"
        f.write(sql)
    f.write("\n")

def generate_booking_details(f):
    f.write("-- (9) BookingDetails\n")
    used_booking_room_pairs = set()
    for _ in range(NUM_BOOKING_DETAILS):
        while True:
            booking_id = random.choice(booking_ids)
            room_id = random.choice(room_ids)
            if (booking_id, room_id) not in used_booking_room_pairs:
                used_booking_room_pairs.add((booking_id, room_id))
                break
        duration_days = random.randint(1, 14)
        num_of_guest = random.randint(1, 5)
        checkin_date = fake.date_between_dates(date_start=DWH_START_DATE, date_end=DWH_END_DATE - timedelta(days=15))
        checkout_date = checkin_date + timedelta(days=duration_days)
        sql = f"INSERT INTO BookingDetail (booking_id, room_id, duration_days, checkin_date, checkout_date, num_of_guest) VALUES ({booking_id}, {room_id}, {duration_days}, TO_DATE('{checkin_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), TO_DATE('{checkout_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {num_of_guest});\n"
        f.write(sql)
    f.write("\n")

# REVISED: Added quantity, total_amount and changed PK logic
def generate_guest_services(f):
    f.write("-- (10) GuestServices\n")
    used_guest_service_date_triplets = set()
    for _ in range(NUM_GUEST_SERVICES):
        while True:
            guest_id = random.choice(guest_ids)
            service_id = random.choice(service_ids)
            usage_date = fake.date_between_dates(date_start=DWH_START_DATE, date_end=DWH_END_DATE)
            if (guest_id, service_id, usage_date) not in used_guest_service_date_triplets:
                 used_guest_service_date_triplets.add((guest_id, service_id, usage_date))
                 break
        booking_date = usage_date - timedelta(days=random.randint(0, 60))
        if booking_date < DWH_START_DATE:
            booking_date = DWH_START_DATE

        quantity = random.randint(1, 3)
        unit_price = service_prices.get(service_id, 0)
        total_amount = round(quantity * unit_price, 2)

        sql = f"INSERT INTO GuestService (guest_id, service_id, booking_date, usage_date, quantity, total_amount) VALUES ({guest_id}, {service_id}, TO_DATE('{booking_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), TO_DATE('{usage_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {quantity}, {total_amount});\n"
        f.write(sql)
    f.write("\n")

# --- Main execution ---
if __name__ == "__main__":
    start_time = datetime.now()
    print(f"Starting data generation at {start_time.strftime('%H:%M:%S')}...")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("-- ====================================================================\n")
        f.write("-- Generated OLTP Insert Data for Oracle 11g (REVISED)\n")
        f.write("-- ====================================================================\n\n")
        f.write("-- Disable PK triggers to allow explicit ID insertion\n")
        f.write("ALTER TRIGGER trg_hotel_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_guest_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_jobs_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_department_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_employee_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_booking_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_room_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_service_pk DISABLE;\n\n")
        f.write("SET DEFINE OFF;\n\n")
        generate_hotels(f)
        generate_guests(f)
        generate_jobs(f)
        generate_departments(f)
        generate_rooms(f)
        generate_services(f)
        generate_employees(f)
        generate_bookings(f)
        generate_booking_details(f)
        generate_guest_services(f)
        f.write("SET DEFINE ON;\n\n")
        f.write("-- Re-enable PK triggers after insertion\n")
        f.write("ALTER TRIGGER trg_hotel_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_guest_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_jobs_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_department_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_employee_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_booking_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_room_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_service_pk ENABLE;\n\n")
        f.write("COMMIT;\n")
    end_time = datetime.now()
    print(f"Successfully generated {OUTPUT_FILE} at {end_time.strftime('%H:%M:%S')}")
    print(f"Total time taken: {end_time - start_time}")