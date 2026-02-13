-- Test Database Schema
-- Based on db/ovid.db structure
-- For use in integration tests only

-- Article Types Table
CREATE TABLE IF NOT EXISTS "article_types" (
    article_type_id INTEGER PRIMARY KEY,
    name            VARCHAR(200) NOT NULL UNIQUE,
    type            VARCHAR(200) NOT NULL UNIQUE,
    directory       VARCHAR(200) NOT NULL UNIQUE,
    description     VARCHAR(200) NOT NULL UNIQUE
);

-- Articles Table
CREATE TABLE IF NOT EXISTS "articles" (
    article_id      INTEGER PRIMARY KEY,
    title           VARCHAR(100)   NOT NULL,
    slug            VARCHAR(100)   NOT NULL,
    description     VARCHAR(1000) NOT NULL,
    article_type_id INTEGER        NOT NULL,
    sort_order      INTEGER        NOT NULL,
    available       BOOLEAN        NOT NULL DEFAULT TRUE,
    created         TEXT           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (article_type_id, sort_order),
    UNIQUE (article_type_id, title),
    UNIQUE (article_type_id, slug)
);

-- Images Table
CREATE TABLE IF NOT EXISTS images (
    image_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    filename    VARCHAR(255) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_images_filename ON images(filename);

-- Test Data

-- Article Types
INSERT OR IGNORE INTO article_types (article_type_id, name, type, directory, description) VALUES
    (1, 'Blog Posts', 'blog', 'blog', 'Personal blog posts'),
    (2, 'Articles', 'article', 'articles', 'Technical articles');

-- Sample Articles
INSERT OR IGNORE INTO articles (article_id, title, slug, description, article_type_id, sort_order, available) VALUES
    (1, 'Test Blog Post', 'test-blog-post', 'A test blog post for integration testing', 1, 1, TRUE),
    (2, 'Test Article', 'test-article', 'A test article for integration testing', 2, 1, TRUE),
    (3, 'Unavailable Post', 'unavailable-post', 'A post that is not available', 1, 2, FALSE);

-- Sample Images
INSERT OR IGNORE INTO images (image_id, filename, description) VALUES
    (1, 'test-image.jpg', 'A test image for unit tests'),
    (2, 'sample-photo.png', 'Another test image');
