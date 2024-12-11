-- Deploy ovid:images to sqlite

BEGIN;

	CREATE TABLE images (
		image_id    INTEGER PRIMARY KEY AUTOINCREMENT,
		filename    VARCHAR(255) NOT NULL,
		description TEXT,
		created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE INDEX idx_images_filename ON images(filename);

COMMIT;
