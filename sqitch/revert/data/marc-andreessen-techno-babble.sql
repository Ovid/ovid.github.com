-- Revert ovid:data/marc-andreessen-techno-babble to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'marc-andreessen-techno-babble' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
