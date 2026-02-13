-- Revert ovid:data/introducing-the-arxiv-explorer to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'introducing-the-arxiv-explorer' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
