-- Revert ovid:data/how-i-landed-the-worst-best-job to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'how-i-landed-the-worst-best-job' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
