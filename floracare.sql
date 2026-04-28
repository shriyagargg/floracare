-- ==========================================================
-- FLORA CARE PRO - COMPLETE SQL FILE
-- Covers: DDL, DML, DQL, TCL, Views, Stored Procedures & Functions
-- ==========================================================

DROP DATABASE IF EXISTS floracare;
CREATE DATABASE floracare;
USE floracare;

-- ==========================================================
-- DDL: CREATE TABLES WITH PK / FK CONSTRAINTS
-- ==========================================================

CREATE TABLE users (
    user_id   INT AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL UNIQUE,
    password  VARCHAR(100) NOT NULL,
    city      VARCHAR(100)
);

CREATE TABLE species (
    species_id          INT AUTO_INCREMENT PRIMARY KEY,
    species_name        VARCHAR(100) NOT NULL,
    sunlight_need       VARCHAR(100),
    watering_frequency  INT,          -- days between watering
    toxicity_level      VARCHAR(50)
);

CREATE TABLE plants (
    plant_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    species_id   INT NOT NULL,
    plant_name   VARCHAR(100) NOT NULL,
    age_months   INT DEFAULT 0,
    location     VARCHAR(50),
    health_score FLOAT DEFAULT 100,
    CONSTRAINT fk_plant_user    FOREIGN KEY (user_id)    REFERENCES users(user_id)   ON DELETE CASCADE,
    CONSTRAINT fk_plant_species FOREIGN KEY (species_id) REFERENCES species(species_id) ON DELETE CASCADE
);

CREATE TABLE care_tasks (
    task_id   INT AUTO_INCREMENT PRIMARY KEY,
    plant_id  INT NOT NULL,
    task_type VARCHAR(100),
    due_date  DATE,
    status    VARCHAR(50) DEFAULT 'Pending',
    CONSTRAINT fk_task_plant FOREIGN KEY (plant_id) REFERENCES plants(plant_id) ON DELETE CASCADE
);

CREATE TABLE plant_logs (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    plant_id     INT NOT NULL,
    action_taken VARCHAR(200),
    notes        TEXT,
    log_date     DATE,
    CONSTRAINT fk_log_plant FOREIGN KEY (plant_id) REFERENCES plants(plant_id) ON DELETE CASCADE
);

CREATE TABLE reminders (
    reminder_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    plant_id      INT NOT NULL,
    reminder_type VARCHAR(100),
    reminder_time DATETIME,
    active        TINYINT DEFAULT 1,
    CONSTRAINT fk_reminder_user  FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE,
    CONSTRAINT fk_reminder_plant FOREIGN KEY (plant_id) REFERENCES plants(plant_id) ON DELETE CASCADE
);

CREATE TABLE disease_reports (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    plant_id  INT NOT NULL,
    symptom   VARCHAR(200),
    diagnosis VARCHAR(200),
    severity  VARCHAR(50),
    CONSTRAINT fk_disease_plant FOREIGN KEY (plant_id) REFERENCES plants(plant_id) ON DELETE CASCADE
);

CREATE TABLE community_posts (
    post_id  INT AUTO_INCREMENT PRIMARY KEY,
    user_id  INT NOT NULL,
    title    VARCHAR(200),
    content  TEXT,
    likes    INT DEFAULT 0,
    CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE achievements (
    achievement_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    badge_name     VARCHAR(100),
    earned_on      DATE,
    CONSTRAINT fk_achievement_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ==========================================================
-- DML: INSERT 50+ ENTRIES
-- ==========================================================

-- ── Users (10) ─────────────────────────────────────────────
INSERT INTO users (name, email, password, city) VALUES
('Aarav Sharma',   'aarav@email.com',   'pass123', 'Mumbai'),
('Priya Patel',    'priya@email.com',   'pass123', 'Ahmedabad'),
('Rohan Mehta',    'rohan@email.com',   'pass123', 'Delhi'),
('Sneha Joshi',    'sneha@email.com',   'pass123', 'Pune'),
('Karan Singh',    'karan@email.com',   'pass123', 'Jaipur'),
('Ananya Gupta',   'ananya@email.com',  'pass123', 'Bangalore'),
('Vikram Nair',    'vikram@email.com',  'pass123', 'Chennai'),
('Meera Iyer',     'meera@email.com',   'pass123', 'Hyderabad'),
('Arjun Reddy',    'arjun@email.com',   'pass123', 'Kolkata'),
('Divya Kapoor',   'divya@email.com',   'pass123', 'Lucknow');

-- ── Species (10) ───────────────────────────────────────────
INSERT INTO species (species_name, sunlight_need, watering_frequency, toxicity_level) VALUES
('Rose',           'Full Sun',        3,  'None'),
('Aloe Vera',      'Partial Sun',     14, 'Low'),
('Tulsi',          'Full Sun',        2,  'None'),
('Money Plant',    'Low Light',       7,  'Low'),
('Peace Lily',     'Low Light',       5,  'Medium'),
('Cactus',         'Full Sun',        21, 'None'),
('Fern',           'Shade',           4,  'None'),
('Jasmine',        'Full Sun',        3,  'None'),
('Lavender',       'Full Sun',        7,  'None'),
('Snake Plant',    'Low Light',       14, 'Low');

-- ── Plants (10) ────────────────────────────────────────────
INSERT INTO plants (user_id, species_id, plant_name, age_months, location, health_score) VALUES
(1,  1,  'Red Rose',        12, 'Outdoor',  92),
(2,  2,  'Aloe Beauty',     24, 'Indoor',   88),
(3,  3,  'Holy Tulsi',       6, 'Balcony',  95),
(4,  4,  'Lucky Money',     18, 'Indoor',   78),
(5,  5,  'Peace Queen',      9, 'Indoor',   65),
(6,  6,  'Desert King',     36, 'Outdoor',  99),
(7,  7,  'Green Fern',       3, 'Indoor',   72),
(8,  8,  'White Jasmine',   15, 'Terrace',  85),
(9,  9,  'Purple Lavender', 20, 'Outdoor',  90),
(10, 10, 'Iron Snake',      30, 'Indoor',   80);

-- ── Care Tasks (10) ────────────────────────────────────────
INSERT INTO care_tasks (plant_id, task_type, due_date, status) VALUES
(1,  'Watering',    '2025-05-01', 'Pending'),
(2,  'Fertilizing', '2025-05-02', 'Pending'),
(3,  'Pruning',     '2025-05-03', 'Completed'),
(4,  'Repotting',   '2025-05-04', 'Pending'),
(5,  'Watering',    '2025-05-05', 'Completed'),
(6,  'Fertilizing', '2025-05-06', 'Pending'),
(7,  'Pruning',     '2025-05-07', 'Pending'),
(8,  'Watering',    '2025-05-08', 'Completed'),
(9,  'Repotting',   '2025-05-09', 'Pending'),
(10, 'Watering',    '2025-05-10', 'Pending');

-- ── Plant Logs (5) ─────────────────────────────────────────
INSERT INTO plant_logs (plant_id, action_taken, notes, log_date) VALUES
(1, 'Watered',     'Soil was dry',          '2025-04-20'),
(2, 'Fertilized',  'Used NPK mix',          '2025-04-21'),
(3, 'Pruned',      'Removed dead leaves',   '2025-04-22'),
(4, 'Repotted',    'Moved to bigger pot',   '2025-04-23'),
(5, 'Watered',     'Leaves looked droopy',  '2025-04-24');

-- ── Reminders (5) ──────────────────────────────────────────
INSERT INTO reminders (user_id, plant_id, reminder_type, reminder_time, active) VALUES
(1, 1, 'Watering',    '2025-05-01 08:00:00', 1),
(2, 2, 'Fertilizing', '2025-05-02 09:00:00', 1),
(3, 3, 'Pruning',     '2025-05-03 07:30:00', 1),
(4, 4, 'Repotting',   '2025-05-04 10:00:00', 0),
(5, 5, 'Watering',    '2025-05-05 08:00:00', 1);

-- ── Disease Reports (5) ────────────────────────────────────
INSERT INTO disease_reports (plant_id, symptom, diagnosis, severity) VALUES
(1, 'Yellow leaves',    'Overwatering',       'Low'),
(2, 'Brown tips',       'Low humidity',       'Low'),
(3, 'Wilting',          'Root rot',           'High'),
(4, 'White spots',      'Powdery mildew',     'Medium'),
(5, 'Black stems',      'Fungal infection',   'High');

-- ── Community Posts (5) ────────────────────────────────────
INSERT INTO community_posts (user_id, title, content, likes) VALUES
(1, 'My Rose is blooming!',       'Finally got my rose to bloom after 3 months.',  12),
(2, 'Aloe Vera tips',             'Best way to care for aloe in summer.',           8),
(3, 'Tulsi growing guide',        'Step by step guide for growing tulsi at home.',  15),
(4, 'Money plant in water',       'Can money plant survive only in water? Yes!',    20),
(5, 'Peace lily not flowering',   'My peace lily hasnt flowered in 6 months.',      5);

-- ── Achievements (5) ───────────────────────────────────────
INSERT INTO achievements (user_id, badge_name, earned_on) VALUES
(1, 'Green Thumb',      '2025-01-10'),
(2, 'Plant Parent',     '2025-02-14'),
(3, 'Herb Master',      '2025-03-01'),
(4, 'Indoor Expert',    '2025-03-20'),
(5, 'Disease Fighter',  '2025-04-05');


-- ==========================================================
-- ADDITIONAL 20+ DATA ENTRIES
-- ==========================================================

-- ── More Users (5) ─────────────────────────────────────────
INSERT INTO users (name, email, password, city) VALUES
('Ravi Kumar',     'ravi@email.com',     'pass123', 'Chandigarh'),
('Neha Sharma',    'neha@email.com',     'pass123', 'Indore'),
('Amit Verma',     'amit@email.com',     'pass123', 'Nagpur'),
('Pooja Singh',    'pooja@email.com',    'pass123', 'Surat'),
('Rahul Jain',     'rahul@email.com',    'pass123', 'Bhopal');

-- ── More Species (5) ───────────────────────────────────────
INSERT INTO species (species_name, sunlight_need, watering_frequency, toxicity_level) VALUES
('Mint',           'Partial Sun',     3,  'None'),
('Bamboo',         'Partial Sun',     5,  'None'),
('Spider Plant',   'Low Light',       7,  'None'),
('Orchid',         'Partial Sun',     10, 'None'),
('Marigold',       'Full Sun',        2,  'None');

-- ── More Plants (15) ───────────────────────────────────────
INSERT INTO plants (user_id, species_id, plant_name, age_months, location, health_score) VALUES
(1,  11, 'Fresh Mint',      4,  'Balcony',  87),
(2,  12, 'Lucky Bamboo',    18, 'Indoor',   92),
(3,  13, 'Spider Web',      12, 'Indoor',   75),
(4,  14, 'Pink Orchid',     24, 'Indoor',   68),
(5,  15, 'Golden Marigold', 3,  'Outdoor',  94),
(6,  1,  'Yellow Rose',     8,  'Outdoor',  89),
(7,  2,  'Healing Aloe',    15, 'Balcony',  82),
(8,  3,  'Sacred Tulsi',    5,  'Terrace',  96),
(9,  4,  'Green Money',     20, 'Indoor',   71),
(10, 5,  'White Peace',     10, 'Indoor',   77),
(11, 6,  'Mini Cactus',     6,  'Indoor',   98),
(12, 7,  'Boston Fern',     9,  'Balcony',  84),
(13, 8,  'Night Jasmine',   14, 'Outdoor',  88),
(14, 9,  'French Lavender', 22, 'Terrace',  91),
(15, 10, 'Tall Snake',      28, 'Indoor',   86);

-- ── More Care Tasks (15) ───────────────────────────────────
INSERT INTO care_tasks (plant_id, task_type, due_date, status) VALUES
(11, 'Watering',    '2025-05-11', 'Pending'),
(12, 'Fertilizing', '2025-05-12', 'Pending'),
(13, 'Pruning',     '2025-05-13', 'Pending'),
(14, 'Watering',    '2025-05-14', 'Completed'),
(15, 'Repotting',   '2025-05-15', 'Pending'),
(16, 'Watering',    '2025-05-16', 'Pending'),
(17, 'Fertilizing', '2025-05-17', 'Completed'),
(18, 'Pruning',     '2025-05-18', 'Pending'),
(19, 'Watering',    '2025-05-19', 'Pending'),
(20, 'Repotting',   '2025-05-20', 'Completed'),
(21, 'Watering',    '2025-05-21', 'Pending'),
(22, 'Fertilizing', '2025-05-22', 'Pending'),
(23, 'Pruning',     '2025-05-23', 'Pending'),
(24, 'Watering',    '2025-05-24', 'Pending'),
(25, 'Repotting',   '2025-05-25', 'Pending');

-- ── More Plant Logs (10) ───────────────────────────────────
INSERT INTO plant_logs (plant_id, action_taken, notes, log_date) VALUES
(6,  'Watered',     'Morning watering',       '2025-04-25'),
(7,  'Fertilized',  'Organic fertilizer',     '2025-04-26'),
(8,  'Pruned',      'Trimmed overgrowth',     '2025-04-27'),
(9,  'Repotted',    'Changed to clay pot',    '2025-04-28'),
(10, 'Watered',     'Evening watering',       '2025-04-29'),
(11, 'Fertilized',  'NPK 10-10-10',           '2025-04-30'),
(12, 'Pruned',      'Removed yellow leaves',  '2025-05-01'),
(13, 'Watered',     'Checked soil moisture',  '2025-05-02'),
(14, 'Repotted',    'Larger pot needed',      '2025-05-03'),
(15, 'Fertilized',  'Compost added',          '2025-05-04');

-- ── More Reminders (10) ────────────────────────────────────
INSERT INTO reminders (user_id, plant_id, reminder_type, reminder_time, active) VALUES
(6,  11, 'Watering',    '2025-05-11 08:00:00', 1),
(7,  12, 'Fertilizing', '2025-05-12 09:00:00', 1),
(8,  13, 'Pruning',     '2025-05-13 07:30:00', 1),
(9,  14, 'Watering',    '2025-05-14 08:00:00', 1),
(10, 15, 'Repotting',   '2025-05-15 10:00:00', 1),
(11, 16, 'Watering',    '2025-05-16 08:00:00', 1),
(12, 17, 'Fertilizing', '2025-05-17 09:00:00', 0),
(13, 18, 'Pruning',     '2025-05-18 07:30:00', 1),
(14, 19, 'Watering',    '2025-05-19 08:00:00', 1),
(15, 20, 'Repotting',   '2025-05-20 10:00:00', 1);

-- ── More Disease Reports (10) ──────────────────────────────
INSERT INTO disease_reports (plant_id, symptom, diagnosis, severity) VALUES
(6,  'Leaf spots',      'Bacterial infection',  'Medium'),
(7,  'Drooping leaves', 'Underwatering',        'Low'),
(8,  'Brown edges',     'Nutrient deficiency',  'Medium'),
(9,  'Sticky residue',  'Aphid infestation',    'High'),
(10, 'Pale leaves',     'Iron deficiency',      'Low'),
(11, 'Curling leaves',  'Pest damage',          'Medium'),
(12, 'Root damage',     'Overwatering',         'High'),
(13, 'Mold growth',     'Fungal disease',       'High'),
(14, 'Stunted growth',  'Poor soil quality',    'Medium'),
(15, 'Yellowing',       'Nitrogen deficiency',  'Low');

-- ── More Community Posts (10) ──────────────────────────────
INSERT INTO community_posts (user_id, title, content, likes) VALUES
(6,  'Indoor gardening tips',        'Best plants for small apartments.',           18),
(7,  'Organic fertilizers',          'How to make compost at home.',                22),
(8,  'Pest control naturally',       'Natural ways to keep pests away.',            14),
(9,  'Watering schedule guide',      'Perfect watering routine for beginners.',     25),
(10, 'Succulent care 101',           'Everything about caring for succulents.',     30),
(11, 'Herb garden setup',            'Starting your kitchen herb garden.',          16),
(12, 'Plant propagation',            'Easy methods to propagate plants.',           19),
(13, 'Seasonal planting',            'What to plant in each season.',               11),
(14, 'Balcony garden ideas',         'Transform your balcony into a garden.',       27),
(15, 'Plant disease prevention',     'How to prevent common plant diseases.',       21);

-- ── More Achievements (10) ─────────────────────────────────
INSERT INTO achievements (user_id, badge_name, earned_on) VALUES
(6,  'Watering Pro',        '2025-04-10'),
(7,  'Fertilizer Expert',   '2025-04-12'),
(8,  'Pruning Master',      '2025-04-15'),
(9,  'Community Star',      '2025-04-18'),
(10, 'Plant Collector',     '2025-04-20'),
(11, 'Early Bird',          '2025-04-22'),
(12, 'Organic Gardener',    '2025-04-25'),
(13, 'Pest Controller',     '2025-04-27'),
(14, 'Balcony Expert',      '2025-04-28'),
(15, 'Plant Saver',         '2025-04-29');


-- ==========================================================
-- DML: UPDATE
-- ==========================================================

-- Update health score of a plant
UPDATE plants SET health_score = 95 WHERE plant_id = 5;

-- Mark all overdue tasks as Completed
UPDATE care_tasks SET status = 'Completed' WHERE due_date < CURDATE() AND status = 'Pending';

-- Increase likes on a popular post
UPDATE community_posts SET likes = likes + 1 WHERE post_id = 4;


-- ==========================================================
-- DML: DELETE
-- ==========================================================

-- Delete inactive reminders
DELETE FROM reminders WHERE active = 0;

-- Delete low severity disease reports (safe cleanup)
DELETE FROM disease_reports WHERE severity = 'Low' AND plant_id = 2;


-- ==========================================================
-- TCL: TRANSACTIONS WITH COMMIT & ROLLBACK
-- ==========================================================

-- Transaction 1: Add a new user and their plant atomically
START TRANSACTION;
    INSERT INTO users (name, email, password, city)
    VALUES ('Test User', 'testuser@email.com', 'test123', 'Surat');

    INSERT INTO plants (user_id, species_id, plant_name, age_months, location, health_score)
    VALUES (LAST_INSERT_ID(), 1, 'Test Rose', 2, 'Balcony', 88);
COMMIT;

-- Transaction 2: Rollback example (simulates an error scenario)
START TRANSACTION;
    UPDATE plants SET health_score = 0 WHERE plant_id = 1;
ROLLBACK;
-- health_score of plant_id=1 is restored to original value


-- ==========================================================
-- DQL: MULTI-TABLE JOINS
-- ==========================================================

-- 1. Plants with their owner name and species
SELECT
    p.plant_id,
    p.plant_name,
    u.name        AS owner,
    s.species_name,
    p.health_score
FROM plants p
JOIN users   u ON p.user_id    = u.user_id
JOIN species s ON p.species_id = s.species_id;

-- 2. Pending tasks with plant name and owner
SELECT
    ct.task_id,
    u.name       AS owner,
    p.plant_name,
    ct.task_type,
    ct.due_date
FROM care_tasks ct
JOIN plants p ON ct.plant_id = p.plant_id
JOIN users  u ON p.user_id   = u.user_id
WHERE ct.status = 'Pending';

-- 3. Disease reports with plant and owner details
SELECT
    dr.report_id,
    u.name       AS owner,
    p.plant_name,
    dr.symptom,
    dr.diagnosis,
    dr.severity
FROM disease_reports dr
JOIN plants p ON dr.plant_id = p.plant_id
JOIN users  u ON p.user_id   = u.user_id;


-- ==========================================================
-- DQL: GROUP BY & HAVING
-- ==========================================================

-- 1. Number of plants per user (only users with more than 0 plants)
SELECT
    u.name,
    COUNT(p.plant_id) AS total_plants
FROM users u
LEFT JOIN plants p ON u.user_id = p.user_id
GROUP BY u.name
HAVING total_plants > 0;

-- 2. Average health score per location
SELECT
    location,
    ROUND(AVG(health_score), 2) AS avg_health
FROM plants
GROUP BY location;

-- 3. Species with more than 1 plant registered
SELECT
    s.species_name,
    COUNT(p.plant_id) AS plant_count
FROM species s
JOIN plants p ON s.species_id = p.species_id
GROUP BY s.species_name
HAVING plant_count > 1;

-- 4. Users who have earned more than 0 achievements
SELECT
    u.name,
    COUNT(a.achievement_id) AS badge_count
FROM users u
JOIN achievements a ON u.user_id = a.user_id
GROUP BY u.name
HAVING badge_count > 0;


-- ==========================================================
-- DQL: SUBQUERIES
-- ==========================================================

-- 1. Plants with health score below the overall average
SELECT plant_name, health_score
FROM plants
WHERE health_score < (SELECT AVG(health_score) FROM plants);

-- 2. Users who have at least one plant
SELECT name FROM users
WHERE user_id IN (SELECT DISTINCT user_id FROM plants);

-- 3. Most liked community post
SELECT title, likes FROM community_posts
WHERE likes = (SELECT MAX(likes) FROM community_posts);

-- 4. Plants that have a disease report with High severity
SELECT plant_name FROM plants
WHERE plant_id IN (
    SELECT plant_id FROM disease_reports WHERE severity = 'High'
);


-- ==========================================================
-- VIEWS
-- ==========================================================

-- View 1: Healthy plants (health score >= 85)
CREATE OR REPLACE VIEW view_healthy_plants AS
SELECT
    p.plant_id,
    p.plant_name,
    u.name       AS owner,
    s.species_name,
    p.health_score
FROM plants p
JOIN users   u ON p.user_id    = u.user_id
JOIN species s ON p.species_id = s.species_id
WHERE p.health_score >= 85;

-- View 2: Pending tasks summary
CREATE OR REPLACE VIEW view_pending_tasks AS
SELECT
    ct.task_id,
    p.plant_name,
    u.name       AS owner,
    ct.task_type,
    ct.due_date
FROM care_tasks ct
JOIN plants p ON ct.plant_id = p.plant_id
JOIN users  u ON p.user_id   = u.user_id
WHERE ct.status = 'Pending';

-- View 3: User plant summary
CREATE OR REPLACE VIEW view_user_plant_summary AS
SELECT
    u.user_id,
    u.name,
    u.city,
    COUNT(p.plant_id)           AS total_plants,
    ROUND(AVG(p.health_score), 2) AS avg_health
FROM users u
LEFT JOIN plants p ON u.user_id = p.user_id
GROUP BY u.user_id, u.name, u.city;

-- Query the views
SELECT * FROM view_healthy_plants;
SELECT * FROM view_pending_tasks;
SELECT * FROM view_user_plant_summary;


-- ==========================================================
-- STORED PROCEDURES
-- ==========================================================

DELIMITER $$

-- Procedure 1: Get all plants for a specific user
CREATE PROCEDURE GetUserPlants(IN p_user_id INT)
BEGIN
    SELECT
        p.plant_id,
        p.plant_name,
        s.species_name,
        p.location,
        p.health_score
    FROM plants p
    JOIN species s ON p.species_id = s.species_id
    WHERE p.user_id = p_user_id;
END$$

-- Procedure 2: Add a care task for a plant
CREATE PROCEDURE AddCareTask(
    IN p_plant_id  INT,
    IN p_task_type VARCHAR(100),
    IN p_due_date  DATE
)
BEGIN
    INSERT INTO care_tasks (plant_id, task_type, due_date, status)
    VALUES (p_plant_id, p_task_type, p_due_date, 'Pending');
    SELECT 'Task added successfully' AS message;
END$$

-- Procedure 3: Update plant health score
CREATE PROCEDURE UpdatePlantHealth(
    IN p_plant_id     INT,
    IN p_health_score FLOAT
)
BEGIN
    UPDATE plants SET health_score = p_health_score WHERE plant_id = p_plant_id;
    SELECT CONCAT('Health updated for plant_id: ', p_plant_id) AS message;
END$$

DELIMITER ;

-- Call the procedures
CALL GetUserPlants(1);
CALL AddCareTask(1, 'Misting', '2025-06-01');
CALL UpdatePlantHealth(5, 88);


-- ==========================================================
-- STORED FUNCTIONS
-- ==========================================================

DELIMITER $$

-- Function 1: Get health status label from score
CREATE FUNCTION GetHealthStatus(score FLOAT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE status VARCHAR(20);
    IF score >= 85 THEN
        SET status = 'Healthy';
    ELSEIF score >= 60 THEN
        SET status = 'Moderate';
    ELSE
        SET status = 'Critical';
    END IF;
    RETURN status;
END$$

-- Function 2: Count total plants for a user
CREATE FUNCTION CountUserPlants(p_user_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM plants WHERE user_id = p_user_id;
    RETURN total;
END$$

DELIMITER ;

-- Use the functions
SELECT
    plant_name,
    health_score,
    GetHealthStatus(health_score) AS health_status
FROM plants;

SELECT
    name,
    CountUserPlants(user_id) AS total_plants
FROM users;
