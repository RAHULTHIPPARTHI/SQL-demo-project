/*DROP DATABASE [DoctorMedicineSystem]
CREATE DATABASE [DoctorMedicineSystem]
*/

-- Creating Roles Table
CREATE TABLE Roles (
    RoleId INT PRIMARY KEY IDENTITY(1,1),
    RoleName VARCHAR(10) NOT NULL
);

-- Creating Users Table
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    RoleId INT FOREIGN KEY REFERENCES Roles(RoleId),
    Name VARCHAR(25) NOT NULL,
    Email VARCHAR(25) UNIQUE NOT NULL,
    Password VARCHAR(15) NOT NULL,
    GovId VARCHAR(25) NOT NULL,
    Contact VARCHAR(10)
);

-- Creating Doctors Table
CREATE TABLE Doctors (
    DoctorId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT FOREIGN KEY REFERENCES Users(UserId),
    Speciality VARCHAR(15) NOT NULL,
    Location VARCHAR(20) NOT NULL
);

-- Creating DoctorAvailability Table
CREATE TABLE DoctorAvailability (
    AvailabilityId INT PRIMARY KEY IDENTITY(1,1),
    DoctorId INT FOREIGN KEY REFERENCES Doctors(DoctorId),
    Date DATE NOT NULL,
    TimeSlot VARCHAR(30) NOT NULL,
    Status VARCHAR(15) CHECK (Status IN ('Available', 'Booked')) NOT NULL
);

-- Creating Appointment Table
CREATE TABLE Appointment (
    AppointmentId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT FOREIGN KEY REFERENCES Users(UserId),
    AvailabilityId INT FOREIGN KEY REFERENCES DoctorAvailability(AvailabilityId),
    AppointmentDate DATE NOT NULL,
    AppointmentTime VARCHAR(30) NOT NULL,
    Status VARCHAR(15) CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled')) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);

ALTER TABLE Appointment DROP CONSTRAINT CK__Appointme__Statu__45F365D3;

ALTER TABLE Appointment 
ADD CONSTRAINT CK_Appointment_Status 
CHECK (Status IN ('Scheduled', 'Rescheduled', 'Cancelled', 'Completed'));


-- Creating Medicine Table
CREATE TABLE Medicine (
    MedicineId INT PRIMARY KEY IDENTITY(1,1),
    MedicineName VARCHAR(25) NOT NULL,
    Description NVARCHAR(100),
    Price DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL
);


CREATE TABLE Prescription (
    PrescriptionId INT PRIMARY KEY IDENTITY(1,1),
    AppointmentId INT NOT NULL FOREIGN KEY REFERENCES Appointment(AppointmentId),
    CreatedAt DATETIME DEFAULT GETDATE()
);



CREATE TABLE PrescriptionDetails (
    PrescriptionDetailId INT PRIMARY KEY IDENTITY(1,1),
    PrescriptionId INT NOT NULL FOREIGN KEY REFERENCES Prescription(PrescriptionId) ON DELETE CASCADE,
    MedicineId INT NOT NULL FOREIGN KEY REFERENCES Medicine(MedicineId),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Dosage NVARCHAR(50),  -- Example: "1 tablet twice a day"
    CreatedAt DATETIME DEFAULT GETDATE()
);



CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    PrescriptionId INT NULL FOREIGN KEY REFERENCES Prescription(PrescriptionId), -- NULL if ordering without a prescription
    OrderDate DATE NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL CHECK (TotalAmount >= 0),
    PaymentStatus VARCHAR(10) NOT NULL CHECK (PaymentStatus IN ('Pending', 'Paid', 'Failed')), -- Updated column
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE OrderDetails (
    OrderDetailId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderId) ON DELETE CASCADE, -- Deletes details if order is deleted
    MedicineId INT NOT NULL FOREIGN KEY REFERENCES Medicine(MedicineId),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Creating Feedback Table
CREATE TABLE Feedback (
    FeedbackId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(UserId),
    DoctorId INT NOT NULL FOREIGN KEY REFERENCES Doctors(DoctorId),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comments NVARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Creating AdminReports Table
CREATE TABLE AdminReports (
    ReportId INT PRIMARY KEY IDENTITY(1,1),
    ReportType VARCHAR(50) NOT NULL,
    ReportDate DATE DEFAULT GETDATE(),
    Details NVARCHAR(500)
);


CREATE TABLE ErrorLog (
    ErrorID INT PRIMARY KEY IDENTITY(1,1),
    ErrorMessage NVARCHAR(255),
    ErrorDateTime DATETIME DEFAULT GETDATE()
);

ALTER TABLE ErrorLog
ADD ProcedureName NVARCHAR(40);


-- Inserting Data into Roles Table (3 rows)
INSERT INTO Roles (RoleName) VALUES ('Admin');
INSERT INTO Roles (RoleName) VALUES ('Doctor');
INSERT INTO Roles (RoleName) VALUES ('Patient');

-- Inserting Data into Users Table (10 rows)
INSERT INTO Users (RoleId, Name, Email, Password, GovId, Contact) VALUES
(1, 'Admin User', 'admin@example.com', 'admin123', 'GOV123456', '9876543210'),
(2, 'Dr. Smith', 'drsmith@example.com', 'password1', 'GOV789123', '9876543211'),
(2, 'Dr. Brown', 'drbrown@example.com', 'password2', 'GOV654321', '9876543212'),
(2, 'Dr. Williams', 'drwilliams@example.com', 'password3', 'GOV456789', '9876543213'),
(2, 'Dr. Taylor', 'drtaylor@example.com', 'password4', 'GOV987654', '9876543214'),
(3, 'John Doe', 'johndoe@example.com', 'password5', 'GOV321654', '9876543215'),
(3, 'Alice Johnson', 'alice@example.com', 'password6', 'GOV159753', '9876543216'),
(3, 'Michael Lee', 'michael@example.com', 'password7', 'GOV753159', '9876543217'),
(3, 'Emily Davis', 'emily@example.com', 'password8', 'GOV258456', '9876543218'),
(3, 'David White', 'david@example.com', 'password9', 'GOV456258', '9876543219');

-- Inserting Data into Doctors Table (5 rows)
INSERT INTO Doctors (UserId, Speciality, Location) VALUES
(2, 'Cardiology', 'New York'),
(3, 'Dermatology', 'Los Angeles'),
(4, 'Pediatrics', 'Chicago'),
(5, 'Neurology', 'Houston'),
(6, 'Orthopedics', 'Phoenix');

-- Inserting Data into DoctorAvailability Table (5 rows)
INSERT INTO DoctorAvailability (DoctorId, Date, TimeSlot, Status) VALUES
(1, '2025-03-05', '10:00 AM', 'Available'),
(2, '2025-03-06', '11:00 AM', 'Booked'),
(3, '2025-03-07', '02:00 PM', 'Available'),
(4, '2025-03-08', '04:00 PM', 'Available'),
(5, '2025-03-09', '01:00 PM', 'Booked');

-- Inserting More Data into DoctorAvailability Table
INSERT INTO DoctorAvailability (DoctorId, Date, TimeSlot, Status) VALUES
(1, '2025-03-05', '11:00 AM', 'Booked'),
(1, '2025-03-05', '12:00 PM', 'Available'),
(2, '2025-03-06', '09:00 AM', 'Available'),
(2, '2025-03-06', '12:00 PM', 'Booked'),
(3, '2025-03-07', '10:00 AM', 'Available'),
(3, '2025-03-07', '03:00 PM', 'Available'),
(4, '2025-03-08', '11:00 AM', 'Booked'),
(4, '2025-03-08', '02:00 PM', 'Available'),
(5, '2025-03-09', '09:00 AM', 'Available'),
(5, '2025-03-09', '03:00 PM', 'Booked'),
(1, '2025-03-10', '10:00 AM', 'Available'),
(1, '2025-03-10', '01:00 PM', 'Booked'),
(2, '2025-03-11', '09:30 AM', 'Available'),
(2, '2025-03-11', '02:30 PM', 'Booked'),
(3, '2025-03-12', '10:45 AM', 'Available'),
(3, '2025-03-12', '01:15 PM', 'Available'),
(4, '2025-03-13', '11:30 AM', 'Available'),
(4, '2025-03-13', '03:45 PM', 'Booked'),
(5, '2025-03-14', '09:15 AM', 'Available'),
(5, '2025-03-14', '02:00 PM', 'Booked');


TRUNCATE table DOCTORAVAILABILITY 

-- Inserting Data into Appointment Table (10 rows)
INSERT INTO Appointment (UserId, AvailabilityId, AppointmentDate, AppointmentTime, Status) VALUES
(6, 1, '2025-03-05', '10:00 AM', 'Scheduled'),
(7, 2, '2025-03-06', '11:00 AM', 'Completed'),
(8, 3, '2025-03-07', '02:00 PM', 'Scheduled'),
(9, 4, '2025-03-08', '04:00 PM', 'Cancelled'),
(10, 5, '2025-03-09', '01:00 PM', 'Scheduled'),
(6, 3, '2025-03-07', '02:00 PM', 'Completed'),
(7, 1, '2025-03-05', '10:00 AM', 'Scheduled'),
(8, 2, '2025-03-06', '11:00 AM', 'Cancelled'),
(9, 4, '2025-03-08', '04:00 PM', 'Scheduled'),
(10, 5, '2025-03-09', '01:00 PM', 'Completed');

-- Inserting Data into Medicine Table (5 rows)
INSERT INTO Medicine (MedicineName, Description, Price, Stock) VALUES
('Paracetamol', 'Pain reliever and fever reducer', 5.00, 100),
('Ibuprofen', 'Anti-inflammatory and pain relief', 7.50, 50),
('Amoxicillin', 'Antibiotic for bacterial infections', 12.00, 80),
('Cetirizine', 'Antihistamine for allergies', 4.50, 60),
('Metformin', 'Diabetes medication', 15.00, 40);

-- Inserting Data into Prescription Table (5 rows)
INSERT INTO Prescription (AppointmentId) VALUES
(1), (2), (3), (4), (5);

-- Inserting Data into PrescriptionDetails Table (Multiple medicines per prescription)
INSERT INTO PrescriptionDetails (PrescriptionId, MedicineId, Quantity, Dosage) VALUES
(1, 1, 2, '1 tablet twice a day'),
(1, 2, 1, '1 tablet once a day'),
(2, 3, 1, '1 capsule thrice a day'),
(3, 4, 2, '1 tablet every night'),
(4, 5, 1, '1 tablet every morning');

-- Inserting Data into Orders Table (5 rows)
INSERT INTO Orders (PrescriptionId, OrderDate, TotalAmount, PaymentStatus) VALUES
(1, '2025-03-05', 20.00, 'Paid'),
(2, '2025-03-06', 12.00, 'Paid'),
(3, '2025-03-07', 15.00, 'Pending'),
(4, '2025-03-08', 30.00, 'Paid'),
(5, '2025-03-09', 10.00, 'Failed');

-- Inserting Data into OrderDetails Table (5 rows)
INSERT INTO OrderDetails (OrderId, MedicineId, Quantity, Price) VALUES
(1, 1, 2, 5.00),
(2, 3, 1, 12.00),
(3, 4, 3, 4.50),
(4, 5, 2, 15.00),
(5, 2, 1, 7.50);


-- Inserting Data into Feedback Table (5 rows)
INSERT INTO Feedback (UserId, DoctorId, Rating, Comments) VALUES
(6, 1, 5, 'Great doctor, very attentive.'),
(7, 2, 4, 'Good experience, but wait time was long.'),
(8, 3, 5, 'Very professional and friendly.'),
(9, 4, 3, 'Decent experience, could improve communication.'),
(10, 5, 4, 'Helpful advice, but a bit rushed.');


-- Inserting Data into AdminReports Table (5 rows)
INSERT INTO AdminReports (ReportType, Details) VALUES
('Daily Appointments', 'Report on total appointments for the day.'),
('Monthly Revenue', 'Summary of total revenue for the month.'),
('Doctor Availability', 'Current availability status of doctors.'),
('Patient Feedback', 'Analysis of patient feedback received.'),
('Order Summary', 'Details of orders placed in the last week.');


SELECT * FROM [dbo].[ROLES]
SELECT * FROM [dbo].[USERS]
SELECT * FROM [dbo].[DOCTORS]
SELECT * FROM [dbo].[DOCTORAVAILABILITY]
SELECT * FROM [dbo].[APPOINTMENT]
SELECT * FROM [dbo].[MEDICINE]
SELECT * FROM [dbo].[PRESCRIPTION]
SELECT * FROM [dbo].[PrescriptionDetails]
SELECT * FROM [dbo].[ORDERS]
SELECT * FROM [dbo].[ORDERDETAILS]
SELECT * FROM [dbo].[Feedback]
SELECT * FROM [dbo].[AdminReports]
