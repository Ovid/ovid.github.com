-- Revert ovid:images from sqlite

BEGIN;

    DROP TABLE images;

COMMIT;
