-- Portfolio query examples. Run after 01_schema.sql and 02_seed_data.sql.

-- 1. Active members ordered by join date.
SELECT member_name AS "Full Name", email, city, join_date
FROM members
WHERE status = 'active'
ORDER BY join_date;

-- 2. Distinct member cities.
SELECT DISTINCT city
FROM members
WHERE city IS NOT NULL
ORDER BY city;

-- 3. Sessions with their class, category, and trainer.
SELECT s.session_id, s.starts_at, s.room, s.status,
       c.class_name, cat.category_name, t.trainer_name
FROM sessions s
JOIN classes c ON c.class_id = s.class_id
JOIN categories cat ON cat.category_id = c.category_id
LEFT JOIN trainers t ON t.trainer_id = s.trainer_id
ORDER BY s.starts_at;

-- 4. Booking totals and paid revenue by class.
SELECT c.class_name,
       COUNT(b.booking_id) FILTER (WHERE b.attendance_status <> 'cancelled') AS bookings,
       COALESCE(SUM(b.payment_amount) FILTER (WHERE b.payment_status = 'paid'), 0) AS paid_revenue
FROM classes c
LEFT JOIN sessions s ON s.class_id = c.class_id
LEFT JOIN bookings b ON b.session_id = s.session_id
GROUP BY c.class_id, c.class_name
ORDER BY paid_revenue DESC, c.class_name;

-- 5. Average rating by trainer.
SELECT t.trainer_name, ROUND(AVG(b.rating), 2) AS average_rating
FROM trainers t
LEFT JOIN sessions s ON s.trainer_id = t.trainer_id
LEFT JOIN bookings b ON b.session_id = s.session_id AND b.rating IS NOT NULL
GROUP BY t.trainer_id, t.trainer_name
ORDER BY average_rating DESC NULLS LAST;

-- 6. Members with no bookings.
SELECT m.member_id, m.member_name, m.email
FROM members m
LEFT JOIN bookings b ON b.member_id = m.member_id
WHERE b.booking_id IS NULL
ORDER BY m.member_name;

-- 7. Session occupancy, excluding cancelled bookings.
SELECT s.session_id, c.class_name, c.max_capacity,
       COUNT(b.booking_id) FILTER (WHERE b.attendance_status <> 'cancelled') AS reserved,
       c.max_capacity - COUNT(b.booking_id) FILTER (WHERE b.attendance_status <> 'cancelled') AS available
FROM sessions s
JOIN classes c ON c.class_id = s.class_id
LEFT JOIN bookings b ON b.session_id = s.session_id
GROUP BY s.session_id, c.class_id, c.class_name, c.max_capacity
ORDER BY s.starts_at;

-- 8. Monthly member sign-ups.
SELECT DATE_TRUNC('month', join_date)::date AS month, COUNT(*) AS new_members
FROM members
GROUP BY DATE_TRUNC('month', join_date)
ORDER BY month;

-- 9. Top members by attended sessions.
SELECT m.member_name,
       COUNT(*) FILTER (WHERE b.attendance_status = 'attended') AS attended_sessions,
       m.loyalty_points
FROM members m
LEFT JOIN bookings b ON b.member_id = m.member_id
GROUP BY m.member_id, m.member_name, m.loyalty_points
ORDER BY attended_sessions DESC, m.member_name;

-- 10. Upcoming scheduled sessions.
SELECT c.class_name, s.starts_at, s.ends_at, s.room, t.trainer_name
FROM sessions s
JOIN classes c ON c.class_id = s.class_id
LEFT JOIN trainers t ON t.trainer_id = s.trainer_id
WHERE s.status = 'scheduled' AND s.starts_at >= CURRENT_TIMESTAMP
ORDER BY s.starts_at;

