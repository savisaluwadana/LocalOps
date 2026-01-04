-- Blog Platform Schema

-- Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    role VARCHAR(20) DEFAULT 'author',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blogs (multi-tenant)
CREATE TABLE blogs (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER REFERENCES users(id),
    slug VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    logo_url TEXT,
    domain VARCHAR(255),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categories
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER REFERENCES blogs(id),
    slug VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES categories(id),
    UNIQUE(blog_id, slug)
);

-- Posts
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER REFERENCES blogs(id),
    author_id INTEGER REFERENCES users(id),
    slug VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    excerpt TEXT,
    content TEXT,
    featured_image TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    meta_title VARCHAR(255),
    meta_description TEXT,
    published_at TIMESTAMP,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blog_id, slug)
);

-- Post categories (many-to-many)
CREATE TABLE post_categories (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, category_id)
);

-- Tags
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER REFERENCES blogs(id),
    slug VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    UNIQUE(blog_id, slug)
);

-- Post tags (many-to-many)
CREATE TABLE post_tags (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- Comments
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    author_name VARCHAR(100) NOT NULL,
    author_email VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    parent_id INTEGER REFERENCES comments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Media
CREATE TABLE media (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER REFERENCES blogs(id),
    uploader_id INTEGER REFERENCES users(id),
    filename VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    mime_type VARCHAR(100),
    size_bytes INTEGER,
    alt_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_posts_blog ON posts(blog_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published ON posts(published_at);
CREATE INDEX idx_comments_post ON comments(post_id);

-- Sample data
INSERT INTO users (email, password_hash, name, role) VALUES
('admin@blog.com', '$2b$10$hash', 'Admin User', 'admin'),
('author@blog.com', '$2b$10$hash', 'John Author', 'author');

INSERT INTO blogs (owner_id, slug, title, description) VALUES
(1, 'tech-blog', 'Tech Blog', 'A blog about technology');

INSERT INTO categories (blog_id, slug, name) VALUES
(1, 'tutorials', 'Tutorials'),
(1, 'news', 'News'),
(1, 'reviews', 'Reviews');

INSERT INTO posts (blog_id, author_id, slug, title, content, status, published_at) VALUES
(1, 2, 'hello-world', 'Hello World', 'Welcome to our blog!', 'published', NOW()),
(1, 2, 'getting-started', 'Getting Started Guide', 'This is a guide...', 'published', NOW());
