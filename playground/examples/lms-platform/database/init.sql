-- LMS Schema

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'student',
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructor_id INTEGER REFERENCES users(id),
    thumbnail_url VARCHAR(500),
    price DECIMAL(10, 2) DEFAULT 0,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lessons (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    video_url VARCHAR(500),
    duration_minutes INTEGER,
    order_index INTEGER,
    is_free BOOLEAN DEFAULT FALSE
);

CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    course_id INTEGER REFERENCES courses(id),
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, course_id)
);

CREATE TABLE lesson_progress (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    lesson_id INTEGER REFERENCES lessons(id),
    completed_at TIMESTAMP,
    UNIQUE(user_id, lesson_id)
);

CREATE TABLE certificates (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    course_id INTEGER REFERENCES courses(id),
    certificate_number VARCHAR(50) UNIQUE DEFAULT gen_random_uuid()::TEXT,
    issued_at TIMESTAMP,
    UNIQUE(user_id, course_id)
);

CREATE TABLE quizzes (
    id SERIAL PRIMARY KEY,
    lesson_id INTEGER REFERENCES lessons(id),
    question TEXT NOT NULL,
    options JSONB,
    correct_answer INTEGER
);

-- Sample data
INSERT INTO users (name, email, role) VALUES
('John Instructor', 'instructor@lms.com', 'instructor'),
('Jane Student', 'student@lms.com', 'student');

INSERT INTO courses (title, description, instructor_id, is_published) VALUES
('Introduction to DevOps', 'Learn DevOps fundamentals', 1, true),
('Docker Mastery', 'Master containerization', 1, true);

INSERT INTO lessons (course_id, title, content, order_index, is_free) VALUES
(1, 'What is DevOps?', 'DevOps is...', 1, true),
(1, 'CI/CD Basics', 'Continuous Integration...', 2, false),
(2, 'Docker Introduction', 'Docker is...', 1, true),
(2, 'Building Images', 'Use Dockerfile...', 2, false);

CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_progress_user ON lesson_progress(user_id);
