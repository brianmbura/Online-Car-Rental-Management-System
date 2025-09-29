-- final_project.sql
-- Online Car Rental Management System
-- Run on MySQL 8.x (InnoDB, utf8mb4)

DROP DATABASE IF EXISTS car_rental_system;
CREATE DATABASE car_rental_system CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
USE car_rental_system;

-- USERS: admins, staff
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150),
  role ENUM('admin','staff','customer_service') NOT NULL DEFAULT 'staff',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- CUSTOMERS: people renting cars
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(30),
  national_id VARCHAR(50) UNIQUE,
  date_of_birth DATE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- LOCATIONS: branches where cars are stored / picked up
CREATE TABLE locations (
  location_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  address VARCHAR(300),
  city VARCHAR(100),
  country VARCHAR(100),
  phone VARCHAR(30),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- CAR CATEGORIES (SUV, Sedan, Hatchback, Luxury etc.)
CREATE TABLE car_categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  daily_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- CARS: each physical car
CREATE TABLE cars (
  car_id INT AUTO_INCREMENT PRIMARY KEY,
  registration_number VARCHAR(50) NOT NULL UNIQUE,
  make VARCHAR(100) NOT NULL,
  model VARCHAR(100) NOT NULL,
  year YEAR,
  color VARCHAR(50),
  category_id INT NOT NULL,
  location_id INT,
  mileage INT DEFAULT 0,
  status ENUM('available','rented','maintenance','reserved') NOT NULL DEFAULT 'available',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES car_categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- CAR FEATURES (GPS, Baby seat etc.)
CREATE TABLE car_features (
  feature_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

-- MANY-TO-MANY: which car has which features
CREATE TABLE car_feature_map (
  car_id INT NOT NULL,
  feature_id INT NOT NULL,
  PRIMARY KEY (car_id, feature_id),
  FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (feature_id) REFERENCES car_features(feature_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RESERVATIONS: an initial booking record
CREATE TABLE reservations (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  reservation_code VARCHAR(50) NOT NULL UNIQUE,
  customer_id INT NOT NULL,
  created_by_user INT NULL,
  pickup_location_id INT NOT NULL,
  dropoff_location_id INT NOT NULL,
  pickup_datetime DATETIME NOT NULL,
  dropoff_datetime DATETIME NOT NULL,
  status ENUM('pending','confirmed','ongoing','completed','cancelled') NOT NULL DEFAULT 'pending',
  total_estimated DECIMAL(12,2) DEFAULT 0.00,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (created_by_user) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (pickup_location_id) REFERENCES locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (dropoff_location_id) REFERENCES locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CHECK (pickup_datetime < dropoff_datetime)
) ENGINE=InnoDB;

-- Reservation may include one or more cars (supports group bookings). Many-to-Many:
CREATE TABLE reservation_cars (
  reservation_id INT NOT NULL,
  car_id INT NOT NULL,
  daily_rate DECIMAL(10,2) NOT NULL,
  pickup_odometer INT,
  dropoff_odometer INT,
  PRIMARY KEY (reservation_id, car_id),
  FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- PAYMENTS
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  reservation_id INT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('cash','card','mpesa','bank_transfer','other') NOT NULL,
  status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  transaction_ref VARCHAR(150),
  FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- MAINTENANCE RECORDS
CREATE TABLE maintenance_records (
  maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
  car_id INT NOT NULL,
  performed_by VARCHAR(150),
  description TEXT,
  cost DECIMAL(12,2) DEFAULT 0.00,
  maintenance_date DATE,
  next_due DATE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- REVIEWS (customer feedback after rental)
CREATE TABLE reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  reservation_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Indexes for faster lookups
CREATE INDEX idx_cars_status ON cars(status);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_customer ON reservations(customer_id);
CREATE INDEX idx_reservation_pickup ON reservations(pickup_datetime);
CREATE INDEX idx_payments_reservation ON payments(reservation_id);

-- Sample seed data (optional) - uncomment to insert demo rows
-- INSERT INTO users (username, email, password_hash, full_name, role) VALUES
-- ('admin','admin@example.com','<hash>','System Admin','admin');

-- INSERT INTO car_categories (name, description, daily_rate) VALUES
-- ('Sedan','Compact sedan cars',2500.00),
-- ('SUV','Sport utility vehicles',4000.00),
-- ('Hatchback','Small hatchback',1800.00);

-- INSERT INTO locations (name, address, city, country, phone) VALUES
-- ('Nairobi Branch','123 Nairobi Rd','Nairobi','Kenya','+254700000000'),
-- ('Mombasa Branch','45 Coast Ave','Mombasa','Kenya','+254700000001');

-- Commit (not necessary in script but explicit for clarity)
COMMIT;
