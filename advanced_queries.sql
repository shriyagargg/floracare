-- ==========================================================
-- FLORA CARE PRO - ADVANCED SQL QUERIES
-- Views, Indexes, Stored Procedures & Functions
-- ==========================================================

USE floracare;

-- ==========================================================
-- VIEWS (Virtual tables for common queries)
-- ==========================================================

-- View 1: Complete plant profile with owner and species details
DROP VIEW IF EXISTS view_plant_profile;
CREATE VIEW view_plant_profile AS
SELECT
    p.plant_id,
    p.plant_name,
    u.user_id,
    u.name AS owner_name,
    u.email AS owner_email,
    u.city,
    s.species_name,
    s.sunlight_need,
    s.watering_frequency,
    s.toxicity_level,
    p.age_months,
    p.location,
    p.health_score,
    CASE
        WHEN p.health_score >= 85 THEN 'Healthy'
        WHEN p.health_score >= 60 THEN 'Moderate'
        ELSE 'Critical'
    END AS health_status
FROM plants p
JOIN users u ON p.user_id = u.user_id
JOIN species s ON p.species_id = s.species_id;

-- View 2: Critical plants needing attention
DROP VIEW IF EXISTS view_critical_plants;
CREATE VIEW view_critical_plants AS
SELECT
    p.plant_id,
    p.plant_name,
    u.name AS owner,
    u.email,
    p.health_score,
    p.location
FROM plants p
JOIN users u ON p.user_id = u.user_id
WHERE p.health_score < 70
ORDER BY p.health_score ASC;

-- View 3: Overdue tasks
DROP VIEW IF EXISTS view_overdue_tasks;
CREATE VIEW view_overdue_tasks AS
SELECT
    ct.task_id,
    p.plant_name,
    u.name AS owner,
    u.email,
    ct.task_type,
    ct.due_date,
    DATEDIFF(CURDATE(), ct.due_date) AS days_overdue
FROM care_tasks ct
JOIN plants p ON ct.plant_id = p.plant_id
JOIN users u ON p.user_id = u.user_id
WHERE ct.status = 'Pending' AND ct.due_date < CURDATE()
ORDER BY days_overdue DESC;

-- View 4: User activity dashboard
DROP VIEW IF EXISTS view_user_dashboard;
CREATE VIEW view_user_dashboard AS
SELECT
    u.user_id,
    u.name,
    u.city,
    COUNT(DISTINCT p.plant_id) AS total_plants,
    ROUND(IFNULL(AVG(p.health_score), 0), 2) AS avg_health,
    COUNT(DISTINCT CASE WHEN ct.status = 'Pending' THEN ct.task_id END) AS pending_tasks,
    COUNT(DISTINCT cp.post_id) AS total_posts,
    COUNT(DISTINCT a.achievement_id) AS badges_earned
FROM users u
LEFT JOIN plants p ON u.user_id = p.user_id
LEFT JOIN care_tasks ct ON p.plant_id = ct.plant_id
LEFT JOIN community_posts cp ON u.user_id = cp.user_id
LEFT JOIN achievements a ON u.user_id = a.user_id
GROUP BY u.user_id, u.name, u.city;

-- View 5: Disease outbreak summary
DROP VIEW IF EXISTS view_disease_summary;
CREATE VIEW view_disease_summary AS
SELECT
    dr.diagnosis,
    dr.severity,
    COUNT(*) AS case_count,
    GROUP_CONCAT(DISTINCT p.plant_name SEPARATOR ', ') AS affected_plants
FROM disease_reports dr
JOIN plants p ON dr.plant_id = p.plant_id
GROUP BY dr.diagnosis, dr.severity
ORDER BY case_count DESC;

-- View 6: Popular community posts
DROP VIEW IF EXISTS view_popular_posts;
CREATE VIEW view_popular_posts AS
SELECT
    cp.post_id,
    u.name AS author,
    cp.title,
    cp.likes,
    SUBSTRING(cp.content, 1, 100) AS preview
FROM community_posts cp
JOIN users u ON cp.user_id = u.user_id
WHERE cp.likes > 5
ORDER BY cp.likes DESC;

-- View 7: Species popularity ranking
DROP VIEW IF EXISTS view_species_ranking;
CREATE VIEW view_species_ranking AS
SELECT
    s.species_id,
    s.species_name,
    COUNT(p.plant_id) AS plant_count,
    ROUND(IFNULL(AVG(p.health_score), 0), 2) AS avg_health,
    s.sunlight_need,
    s.watering_frequency
FROM species s
LEFT JOIN plants p ON s.species_id = p.species_id
GROUP BY s.species_id, s.species_name, s.sunlight_need, s.watering_frequency
ORDER BY plant_count DESC;

-- View 8: Active reminders today
DROP VIEW IF EXISTS view_todays_reminders;
CREATE VIEW view_todays_reminders AS
SELECT
    r.reminder_id,
    u.name AS user_name,
    u.email,
    p.plant_name,
    r.reminder_type,
    r.reminder_time
FROM reminders r
JOIN users u ON r.user_id = u.user_id
JOIN plants p ON r.plant_id = p.plant_id
WHERE r.active = 1 AND DATE(r.reminder_time) = CURDATE()
ORDER BY r.reminder_time;


-- ==========================================================
-- STORED PROCEDURES
-- ==========================================================

DELIMITER $$

-- Procedure 1: Register a new user with validation
DROP PROCEDURE IF EXISTS RegisterUser$$
CREATE PROCEDURE RegisterUser(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(100),
    IN p_city VARCHAR(100)
)
BEGIN
    DECLARE email_exists INT;
    
    SELECT COUNT(*) INTO email_exists FROM users WHERE email = p_email;
    
    IF email_exists > 0 THEN
        SELECT 'Error: Email already registered' AS message;
    ELSE
        INSERT INTO users (name, email, password, city)
        VALUES (p_name, p_email, p_password, p_city);
        SELECT CONCAT('User ', p_name, ' registered successfully') AS message;
    END IF;
END$$

-- Procedure 2: Add plant with automatic first care task
DROP PROCEDURE IF EXISTS AddPlantWithTask$$
CREATE PROCEDURE AddPlantWithTask(
    IN p_user_id INT,
    IN p_species_id INT,
    IN p_plant_name VARCHAR(100),
    IN p_age_months INT,
    IN p_location VARCHAR(50)
)
BEGIN
    DECLARE new_plant_id INT;
    DECLARE watering_freq INT;
    
    INSERT INTO plants (user_id, species_id, plant_name, age_months, location)
    VALUES (p_user_id, p_species_id, p_plant_name, p_age_months, p_location);
    
    SET new_plant_id = LAST_INSERT_ID();
    
    SELECT watering_frequency INTO watering_freq FROM species WHERE species_id = p_species_id;
    
    INSERT INTO care_tasks (plant_id, task_type, due_date, status)
    VALUES (new_plant_id, 'Watering', DATE_ADD(CURDATE(), INTERVAL watering_freq DAY), 'Pending');
    
    SELECT CONCAT('Plant added with ID: ', new_plant_id, '. First watering task scheduled.') AS message;
END$$

-- Procedure 3: Complete task and log action
DROP PROCEDURE IF EXISTS CompleteTask$$
CREATE PROCEDURE CompleteTask(IN p_task_id INT)
BEGIN
    DECLARE v_plant_id INT;
    DECLARE v_task_type VARCHAR(100);
    
    SELECT plant_id, task_type INTO v_plant_id, v_task_type
    FROM care_tasks WHERE task_id = p_task_id;
    
    UPDATE care_tasks SET status = 'Completed' WHERE task_id = p_task_id;
    
    INSERT INTO plant_logs (plant_id, action_taken, notes, log_date)
    VALUES (v_plant_id, v_task_type, 'Task completed via procedure', CURDATE());
    
    SELECT CONCAT('Task ', p_task_id, ' completed and logged') AS message;
END$$

-- Procedure 4: Update plant health and create alert if critical
DROP PROCEDURE IF EXISTS UpdateHealthWithAlert$$
CREATE PROCEDURE UpdateHealthWithAlert(
    IN p_plant_id INT,
    IN p_new_health FLOAT
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_plant_name VARCHAR(100);
    
    SELECT user_id, plant_name INTO v_user_id, v_plant_name
    FROM plants WHERE plant_id = p_plant_id;
    
    UPDATE plants SET health_score = p_new_health WHERE plant_id = p_plant_id;
    
    IF p_new_health < 60 THEN
        INSERT INTO reminders (user_id, plant_id, reminder_type, reminder_time, active)
        VALUES (v_user_id, p_plant_id, 'Health Alert', NOW(), 1);
        
        SELECT CONCAT('Health updated to ', p_new_health, '. ALERT: Critical health!') AS message;
    ELSE
        SELECT CONCAT('Health updated to ', p_new_health) AS message;
    END IF;
END$$

-- Procedure 5: Get user report
DROP PROCEDURE IF EXISTS GetUserReport$$
CREATE PROCEDURE GetUserReport(IN p_user_id INT)
BEGIN
    SELECT
        u.name,
        u.email,
        u.city,
        COUNT(DISTINCT p.plant_id) AS total_plants,
        ROUND(IFNULL(AVG(p.health_score), 0), 2) AS avg_health,
        COUNT(DISTINCT CASE WHEN ct.status = 'Pending' THEN ct.task_id END) AS pending_tasks,
        COUNT(DISTINCT a.achievement_id) AS badges
    FROM users u
    LEFT JOIN plants p ON u.user_id = p.user_id
    LEFT JOIN care_tasks ct ON p.plant_id = ct.plant_id
    LEFT JOIN achievements a ON u.user_id = a.user_id
    WHERE u.user_id = p_user_id
    GROUP BY u.user_id, u.name, u.email, u.city;
END$$

-- Procedure 6: Award achievement badge
DROP PROCEDURE IF EXISTS AwardBadge$$
CREATE PROCEDURE AwardBadge(
    IN p_user_id INT,
    IN p_badge_name VARCHAR(100)
)
BEGIN
    DECLARE badge_exists INT;
    
    SELECT COUNT(*) INTO badge_exists
    FROM achievements
    WHERE user_id = p_user_id AND badge_name = p_badge_name;
    
    IF badge_exists > 0 THEN
        SELECT 'Badge already earned' AS message;
    ELSE
        INSERT INTO achievements (user_id, badge_name, earned_on)
        VALUES (p_user_id, p_badge_name, CURDATE());
        SELECT CONCAT('Badge "', p_badge_name, '" awarded!') AS message;
    END IF;
END$$

-- Procedure 7: Delete user and all related data
DROP PROCEDURE IF EXISTS DeleteUserCompletely$$
CREATE PROCEDURE DeleteUserCompletely(IN p_user_id INT)
BEGIN
    DECLARE v_name VARCHAR(100);
    
    SELECT name INTO v_name FROM users WHERE user_id = p_user_id;
    
    START TRANSACTION;
        DELETE FROM reminders WHERE user_id = p_user_id;
        DELETE FROM achievements WHERE user_id = p_user_id;
        DELETE FROM community_posts WHERE user_id = p_user_id;
        DELETE FROM users WHERE user_id = p_user_id;
    COMMIT;
    
    SELECT CONCAT('User ', v_name, ' and all related data deleted') AS message;
END$$

DELIMITER ;


-- ==========================================================
-- STORED FUNCTIONS
-- ==========================================================

DELIMITER $$

-- Function 1: Calculate plant age in years
DROP FUNCTION IF EXISTS GetPlantAgeYears$$
CREATE FUNCTION GetPlantAgeYears(p_plant_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE age_months INT;
    SELECT age_months INTO age_months FROM plants WHERE plant_id = p_plant_id;
    RETURN ROUND(age_months / 12, 2);
END$$

-- Function 2: Get health status label
DROP FUNCTION IF EXISTS GetHealthLabel$$
CREATE FUNCTION GetHealthLabel(p_health_score FLOAT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF p_health_score >= 85 THEN
        RETURN 'Healthy';
    ELSEIF p_health_score >= 60 THEN
        RETURN 'Moderate';
    ELSE
        RETURN 'Critical';
    END IF;
END$$

-- Function 3: Count pending tasks for a plant
DROP FUNCTION IF EXISTS CountPendingTasks$$
CREATE FUNCTION CountPendingTasks(p_plant_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE task_count INT;
    SELECT COUNT(*) INTO task_count
    FROM care_tasks
    WHERE plant_id = p_plant_id AND status = 'Pending';
    RETURN task_count;
END$$

-- Function 4: Calculate days until next watering
DROP FUNCTION IF EXISTS DaysUntilWatering$$
CREATE FUNCTION DaysUntilWatering(p_plant_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE next_water_date DATE;
    SELECT MIN(due_date) INTO next_water_date
    FROM care_tasks
    WHERE plant_id = p_plant_id AND task_type = 'Watering' AND status = 'Pending';
    
    IF next_water_date IS NULL THEN
        RETURN -1;
    ELSE
        RETURN DATEDIFF(next_water_date, CURDATE());
    END IF;
END$$

-- Function 5: Get user rank by plant count
DROP FUNCTION IF EXISTS GetUserRank$$
CREATE FUNCTION GetUserRank(p_user_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE user_rank INT;
    DECLARE user_plant_count INT;
    
    SELECT COUNT(*) INTO user_plant_count FROM plants WHERE user_id = p_user_id;
    
    SELECT COUNT(DISTINCT user_id) + 1 INTO user_rank
    FROM plants
    GROUP BY user_id
    HAVING COUNT(*) > user_plant_count;
    
    RETURN user_rank;
END$$

-- Function 6: Check if plant needs attention
DROP FUNCTION IF EXISTS NeedsAttention$$
CREATE FUNCTION NeedsAttention(p_plant_id INT)
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    DECLARE health FLOAT;
    DECLARE overdue_tasks INT;
    
    SELECT health_score INTO health FROM plants WHERE plant_id = p_plant_id;
    SELECT COUNT(*) INTO overdue_tasks
    FROM care_tasks
    WHERE plant_id = p_plant_id AND status = 'Pending' AND due_date < CURDATE();
    
    IF health < 70 OR overdue_tasks > 0 THEN
        RETURN 'Yes';
    ELSE
        RETURN 'No';
    END IF;
END$$

-- Function 7: Calculate total likes for a user's posts
DROP FUNCTION IF EXISTS GetUserTotalLikes$$
CREATE FUNCTION GetUserTotalLikes(p_user_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT IFNULL(SUM(likes), 0) INTO total
    FROM community_posts
    WHERE user_id = p_user_id;
    RETURN total;
END$$

DELIMITER ;


-- ==========================================================
-- EXAMPLE USAGE OF VIEWS
-- ==========================================================

SELECT 'Querying view_plant_profile...' AS info;
SELECT * FROM view_plant_profile LIMIT 5;

SELECT 'Querying view_user_dashboard...' AS info;
SELECT * FROM view_user_dashboard LIMIT 5;

SELECT 'Querying view_species_ranking...' AS info;
SELECT * FROM view_species_ranking;


-- ==========================================================
-- EXAMPLE USAGE OF PROCEDURES
-- ==========================================================

SELECT 'Testing procedures...' AS info;

CALL GetUserReport(1);
CALL AwardBadge(1, 'SQL Master');


-- ==========================================================
-- EXAMPLE USAGE OF FUNCTIONS
-- ==========================================================

SELECT 'Testing functions...' AS info;

SELECT
    plant_id,
    plant_name,
    age_months,
    GetPlantAgeYears(plant_id) AS age_years,
    health_score,
    GetHealthLabel(health_score) AS health_status,
    CountPendingTasks(plant_id) AS pending_tasks,
    NeedsAttention(plant_id) AS needs_attention
FROM plants
LIMIT 5;

SELECT
    user_id,
    name,
    GetUserRank(user_id) AS rank,
    GetUserTotalLikes(user_id) AS total_likes
FROM users
LIMIT 5;

SELECT 'All views, procedures, and functions created successfully!' AS status;
