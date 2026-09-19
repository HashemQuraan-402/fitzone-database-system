-- Sample data for local demonstration.
BEGIN;

INSERT INTO categories (category_name, description) VALUES
    ('Yoga', 'Flexibility, balance, and relaxation'),
    ('Cardio', 'Heart health and endurance workouts'),
    ('Strength', 'Progressive resistance training'),
    ('Boxing', 'Technique and combat fitness');

INSERT INTO trainers
    (trainer_name, gender, email, phone, hire_date, specialization, salary, experience_years)
VALUES
    ('Ali Hassan', 'male', 'ali@fitzone.example', '0791111111', '2018-03-10', 'Yoga', 1200, 10),
    ('Sara Ahmad', 'female', 'sara@fitzone.example', '0793333333', '2019-07-01', 'Strength', 1100, 8),
    ('Noor Mohammad', 'female', 'noor@fitzone.example', '0794444444', '2021-02-20', 'Boxing', 900, 4);

UPDATE trainers SET mentor_id = 1 WHERE trainer_id IN (2, 3);

INSERT INTO classes
    (class_name, description, duration_minutes, max_capacity, equipment_required, class_level, price, category_id)
VALUES
    ('Morning Yoga', 'Guided stretching and breathing', 60, 20, FALSE, 'beginner', 15, 1),
    ('HIIT Cardio', 'High-intensity interval training', 45, 18, TRUE, 'intermediate', 18, 2),
    ('Body Pump', 'Full-body strength endurance', 60, 16, TRUE, 'advanced', 22, 3),
    ('Beginner Boxing', 'Footwork and fundamental combinations', 60, 14, TRUE, 'beginner', 18, 4);

INSERT INTO members
    (member_name, gender, birth_date, email, phone, join_date, status, country, city, street)
VALUES
    ('Ahmed Ali', 'male', '1998-05-10', 'ahmed@example.com', '0797000001', CURRENT_DATE - 120, 'active', 'Jordan', 'Amman', 'Street 1'),
    ('Lina Ahmad', 'female', '2000-01-12', 'lina@example.com', '0797000004', CURRENT_DATE - 90, 'active', 'Jordan', 'Amman', 'Street 4'),
    ('Omar Saleh', 'male', '1995-07-19', 'omar@example.com', '0797000003', CURRENT_DATE - 60, 'inactive', 'Jordan', 'Zarqa', 'Street 3'),
    ('Dana Khaled', 'female', '2001-12-17', 'dana@example.com', '0797000008', CURRENT_DATE - 30, 'active', 'Jordan', 'Jerash', 'Street 8');

INSERT INTO sessions (starts_at, ends_at, room, status, notes, class_id, trainer_id) VALUES
    (CURRENT_DATE + TIME '09:00' + INTERVAL '1 day', CURRENT_DATE + TIME '10:00' + INTERVAL '1 day', 'A101', 'scheduled', 'Morning session', 1, 1),
    (CURRENT_DATE + TIME '17:00' + INTERVAL '2 days', CURRENT_DATE + TIME '17:45' + INTERVAL '2 days', 'B201', 'scheduled', 'Evening HIIT', 2, 1),
    (CURRENT_DATE + TIME '15:00' - INTERVAL '7 days', CURRENT_DATE + TIME '16:00' - INTERVAL '7 days', 'C301', 'completed', 'Strength workshop', 3, 2),
    (CURRENT_DATE + TIME '16:00' + INTERVAL '3 days', CURRENT_DATE + TIME '17:00' + INTERVAL '3 days', 'D401', 'scheduled', 'Boxing fundamentals', 4, 3);

INSERT INTO bookings
    (attendance_status, payment_status, payment_amount, rating, comment_on_session, member_id, session_id)
VALUES
    ('booked', 'paid', 15, NULL, NULL, 1, 1),
    ('booked', 'pending', 18, NULL, NULL, 2, 2),
    ('attended', 'paid', 22, 5, 'Excellent coaching', 1, 3),
    ('attended', 'paid', 22, 4, 'Very useful session', 4, 3);

COMMIT;
