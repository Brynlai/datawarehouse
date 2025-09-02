import os
from faker import Faker
import random
import numpy as np
from datetime import datetime, timedelta, date

# ==============================================================================
# DATA SIMULATION CONFIGURATION
# This section controls the shape and trends of the generated data.
# ==============================================================================

# --- Overall Business Size & Growth ---
BASE_BOOKINGS_PER_DAY = 15     # The average number of bookings on a normal day in the first year.
ANNUAL_GROWTH_RATE = 0.03      # 3% underlying year-on-year growth.

# --- Economic Cycles (Multiplier on top of regular growth) ---
# Simulates booms and recessions over the 15-year period.
ECONOMIC_CYCLE = {
    2010: 1.0, 2011: 1.05, 2012: 1.1,  # Early growth
    2013: 1.0, 2014: 0.95, 2015: 0.9,  # Minor recession
    2016: 1.0, 2017: 1.05, 2018: 1.1,  # Recovery
    2019: 1.15, 2020: 0.8, 2021: 1.0, # Major event (e.g., pandemic) and rebound
    2022: 1.2, 2023: 1.1, 2024: 1.05, 2025: 1.0 # Maturing growth
}

# --- Seasonal Demand Multipliers ---
# Q3 (Summer) and Q4 (Holidays) are high seasons. Q1 is low season.
SEASONAL_MULTIPLIERS = {
    1: 0.8,  # Q1: Post-holiday slump
    2: 1.0,  # Q2: Shoulder season
    3: 1.25, # Q3: Summer peak
    4: 1.2   # Q4: Holiday season
}

# --- Festive Period Spikes ---
# Define specific high-demand periods. (Month, Day, Multiplier, Effect Radius in days)
FESTIVE_PERIODS = [
    (12, 25, 2.5, 10), # Christmas: 2.5x bookings for +/- 10 days
    (7, 4, 1.8, 3),   # US Independence Day: 1.8x bookings for +/- 3 days
    (2, 14, 1.5, 2),   # Valentine's Day: 1.5x bookings for +/- 2 days (shorter stays)
]

# --- Pricing Configuration ---
ROOM_BASE_PRICES = {
    'Single': 120.0,
    'Double': 180.0,
    'Deluxe': 250.0,
    'Family': 300.0,
    'Suite': 450.0
}
FESTIVE_PRICE_MULTIPLIER = 1.5 # Prices are 50% higher during festive periods.

# --- General Configuration ---
NUM_HOTELS = 20
NUM_GUESTS = 10000
NUM_JOBS = 15
NUM_ROOMS_PER_HOTEL = 50
NUM_SERVICES_PER_HOTEL = 10
NUM_DEPTS_PER_HOTEL = 5
NUM_EMPLOYEES_PER_HOTEL = 30

DWH_START_DATE = date(2010, 1, 1)
DWH_END_DATE = date(2025, 8, 31)

OUTPUT_FILE = "3_insert_data.sql"
# ==============================================================================
# END OF CONFIGURATION
# ==============================================================================

fake = Faker()

# --- Global lists for FK relationships ---
hotel_ids = list(range(1, NUM_HOTELS + 1))
guest_ids = list(range(1, NUM_GUESTS + 1))
job_ids = list(range(1, NUM_JOBS + 1))
room_ids_by_type = {rtype: [] for rtype in ROOM_BASE_PRICES.keys()}
all_room_ids = []
service_ids = []
department_ids = []
employee_ids = list(range(1, (NUM_HOTELS * NUM_EMPLOYEES_PER_HOTEL) + 1))
service_prices = {}

unique_emails = set()

def get_unique_email(name):
    base_email = f"{name.replace(' ', '.').lower()}@{fake.free_email_domain()}"
    email = base_email
    counter = 1
    while email in unique_emails:
        email = f"{name.replace(' ', '.').lower()}{counter}@{fake.free_email_domain()}"
        counter += 1
    unique_emails.add(email)
    return email

def escape_sql_string(value):
    if value is None: return "NULL"
    return str(value).replace("'", "''").replace('&', 'and')

def get_daily_booking_factor(current_date):
    """Calculates the booking multiplier for a specific day based on all factors."""
    year_index = current_date.year - DWH_START_DATE.year
    annual_growth_factor = (1 + ANNUAL_GROWTH_RATE) ** year_index
    
    economic_factor = ECONOMIC_CYCLE.get(current_date.year, 1.0)
    
    quarter = (current_date.month - 1) // 3 + 1
    seasonal_factor = SEASONAL_MULTIPLIERS.get(quarter, 1.0)

    festive_factor = 1.0
    is_festive = False
    for month, day, multiplier, radius in FESTIVE_PERIODS:
        festive_date = date(current_date.year, month, day)
        if abs((current_date - festive_date).days) <= radius:
            festive_factor = multiplier
            is_festive = True
            break
            
    return annual_growth_factor * economic_factor * seasonal_factor * festive_factor, is_festive

# --- Static Data Generation (unchanged) ---
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
    for i, title in enumerate(job_titles):
        min_sal = random.randint(30000, 50000)
        max_sal = min_sal + random.randint(10000, 30000)
        sql = f"INSERT INTO Jobs (job_id, job_title, min_salary, max_salary) VALUES ({i+1}, '{title}', {min_sal}, {max_sal});\n"
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
    room_id_counter = 1
    for hotel_id in hotel_ids:
        for _ in range(NUM_ROOMS_PER_HOTEL):
            room_type = random.choices(list(ROOM_BASE_PRICES.keys()), weights=[0.3, 0.4, 0.1, 0.1, 0.1], k=1)[0]
            base_price = ROOM_BASE_PRICES[room_type]
            price = round(base_price * random.uniform(0.9, 1.1), 2)
            bed_count = 1 if room_type == 'Single' else (2 if room_type in ['Double', 'Deluxe'] else random.randint(2, 4))
            
            room_ids_by_type[room_type].append(room_id_counter)
            all_room_ids.append(room_id_counter)
            
            sql = f"INSERT INTO Room (room_id, room_type, bed_count, price, hotel_id) VALUES ({room_id_counter}, '{room_type}', {bed_count}, {price}, {hotel_id});\n"
            f.write(sql)
            room_id_counter += 1
    f.write("\n")

def generate_services(f):
    f.write("-- (6) Services\n")
    service_definitions = {
        'Airport Shuttle': 'Transport', 'Room Service': 'Dining', 'Laundry Service': 'Convenience',
        'Spa Treatment': 'Wellness', 'Gym Access': 'Recreation', 'Valet Parking': 'Transport',
        'Conference Room Rental': 'Business', 'Bike Rental': 'Recreation', 'City Tour Package': 'Recreation',
        'Pet Care': 'Convenience'
    }
    service_id_counter = 1
    for hotel_id in hotel_ids:
        for name, s_type in service_definitions.items():
            service_ids.append(service_id_counter)
            price = round(random.uniform(15.0, 200.0), 2)
            service_prices[service_id_counter] = price
            desc = escape_sql_string(f"Provides convenient {name} for our valued guests.")
            sql = f"INSERT INTO Service (service_id, description, service_name, service_price, service_type, hotel_id) VALUES ({service_id_counter}, '{desc}', '{name}', {price}, '{s_type}', {hotel_id});\n"
            f.write(sql)
            service_id_counter += 1
    f.write("\n")

def generate_employees(f):
    f.write("-- (7) Employees\n")
    depts_per_hotel = len(department_ids) // len(hotel_ids)
    for i in employee_ids:
        first_name, last_name = escape_sql_string(fake.first_name()), escape_sql_string(fake.last_name())
        email = get_unique_email(f'{first_name}.{last_name}')
        job_id = random.choice(job_ids)
        hotel_index = (i - 1) // NUM_EMPLOYEES_PER_HOTEL
        start_dept_index, end_dept_index = hotel_index * depts_per_hotel, (hotel_index + 1) * depts_per_hotel
        dept_id = random.choice(department_ids[start_dept_index:end_dept_index])
        sql = f"INSERT INTO Employee (employee_id, first_name, last_name, email, job_id, department_id) VALUES ({i}, '{first_name}', '{last_name}', '{email}', {job_id}, {dept_id});\n"
        f.write(sql)
    f.write("\n")
    
# --- Dynamic Data Generation (NEW LOGIC) ---
def generate_transactional_data(f):
    print("Simulating day-to-day bookings... this may take a moment.")
    
    all_bookings = {}
    all_booking_details = []
    
    booking_id_counter = 1
    current_date = DWH_START_DATE
    
    while current_date <= DWH_END_DATE:
        factor, is_festive = get_daily_booking_factor(current_date)
        num_bookings_today = max(0, int(np.random.poisson(BASE_BOOKINGS_PER_DAY * factor)))
        
        for _ in range(num_bookings_today):
            guest_id = random.choice(guest_ids)
            
            # High-value guests prefer better rooms
            if guest_id % 10 == 0: # 10% of guests are high-value
                room_type = random.choices(list(ROOM_BASE_PRICES.keys()), weights=[0.05, 0.15, 0.2, 0.2, 0.4], k=1)[0]
            else:
                room_type = random.choices(list(ROOM_BASE_PRICES.keys()), weights=[0.4, 0.4, 0.1, 0.05, 0.05], k=1)[0]
            
            room_id = random.choice(room_ids_by_type[room_type])
            
            if is_festive:
                duration = random.randint(3, 7)
                lead_time = random.randint(60, 180)
            else:
                duration = random.randint(1, 5)
                lead_time = random.randint(7, 90)
                
            checkin_date = current_date
            checkout_date = checkin_date + timedelta(days=duration)
            payment_date = checkin_date - timedelta(days=lead_time)
            if payment_date < DWH_START_DATE: payment_date = DWH_START_DATE

            base_price = ROOM_BASE_PRICES[room_type]
            price_multiplier = FESTIVE_PRICE_MULTIPLIER if is_festive else 1.0
            price_per_night = round(base_price * price_multiplier * random.uniform(0.95, 1.05), 2)
            
            detail_info = {
                'booking_id': booking_id_counter,
                'room_id': room_id,
                'duration_days': duration,
                'checkin_date': checkin_date,
                'checkout_date': checkout_date,
                'num_of_guest': random.randint(1, 4)
            }
            
            if booking_id_counter not in all_bookings:
                all_bookings[booking_id_counter] = {
                    'guest_id': guest_id,
                    'payment_date': payment_date,
                    'payment_method': random.choice(['Credit Card', 'Debit Card', 'Bank Transfer']),
                    'total_price': 0
                }
            
            all_bookings[booking_id_counter]['total_price'] += price_per_night * duration
            all_booking_details.append(detail_info)
            booking_id_counter += 1
            
        current_date += timedelta(days=1)
    
    # Write Bookings to file
    f.write("-- (8) Bookings (Simulated with Trends)\n")
    for b_id, b_info in all_bookings.items():
        sql = f"INSERT INTO Booking (booking_id, total_price, payment_method, payment_date, guest_id) VALUES ({b_id}, {b_info['total_price']:.2f}, '{b_info['payment_method']}', TO_DATE('{b_info['payment_date'].strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {b_info['guest_id']});\n"
        f.write(sql)
    f.write("\n")
    
    # Write Booking Details to file
    f.write("-- (9) BookingDetails (Simulated with Trends)\n")
    for bd in all_booking_details:
        sql = f"INSERT INTO BookingDetail (booking_id, room_id, duration_days, checkin_date, checkout_date, num_of_guest) VALUES ({bd['booking_id']}, {bd['room_id']}, {bd['duration_days']}, TO_DATE('{bd['checkin_date'].strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), TO_DATE('{bd['checkout_date'].strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {bd['num_of_guest']});\n"
        f.write(sql)
    f.write("\n")
    
    # Generate Guest Services based on the bookings we just created
    f.write("-- (10) GuestServices (Linked to Bookings)\n")
    used_guest_service_date_triplets = set()
    service_usage_probability = 0.3 # 30% of bookings will have at least one service
    
    for bd in random.sample(all_booking_details, k=int(len(all_booking_details) * service_usage_probability)):
        guest_id = all_bookings[bd['booking_id']]['guest_id']
        service_id = random.choice(service_ids)
        
        # Ensure usage date is within the stay
        usage_date = fake.date_between_dates(date_start=bd['checkin_date'], date_end=bd['checkout_date'] - timedelta(days=1))
        
        if (guest_id, service_id, usage_date) in used_guest_service_date_triplets:
            continue
        used_guest_service_date_triplets.add((guest_id, service_id, usage_date))
        
        booking_date = usage_date - timedelta(days=random.randint(0, 30))
        if booking_date < DWH_START_DATE: booking_date = DWH_START_DATE
        
        quantity = random.randint(1, 2)
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
        f.write("-- Generated OLTP Insert Data for Oracle 11g (SIMULATED WITH TRENDS)\n")
        f.write("-- ====================================================================\n\n")
        f.write("ALTER TRIGGER trg_hotel_pk DISABLE;\nALTER TRIGGER trg_guest_pk DISABLE;\nALTER TRIGGER trg_jobs_pk DISABLE;\nALTER TRIGGER trg_department_pk DISABLE;\nALTER TRIGGER trg_employee_pk DISABLE;\nALTER TRIGGER trg_booking_pk DISABLE;\nALTER TRIGGER trg_room_pk DISABLE;\nALTER TRIGGER trg_service_pk DISABLE;\n\n")
        f.write("SET DEFINE OFF;\n\n")
        
        generate_hotels(f)
        generate_guests(f)
        generate_jobs(f)
        generate_departments(f)
        generate_rooms(f)
        generate_services(f)
        generate_employees(f)
        generate_transactional_data(f)
        
        f.write("SET DEFINE ON;\n\n")
        f.write("ALTER TRIGGER trg_hotel_pk ENABLE;\nALTER TRIGGER trg_guest_pk ENABLE;\nALTER TRIGGER trg_jobs_pk ENABLE;\nALTER TRIGGER trg_department_pk ENABLE;\nALTER TRIGGER trg_employee_pk ENABLE;\nALTER TRIGGER trg_booking_pk ENABLE;\nALTER TRIGGER trg_room_pk ENABLE;\nALTER TRIGGER trg_service_pk ENABLE;\n\n")
        f.write("COMMIT;\n")
        
    end_time = datetime.now()
    print(f"Successfully generated {OUTPUT_FILE} at {end_time.strftime('%H:%M:%S')}")
    print(f"Total time taken: {end_time - start_time}")