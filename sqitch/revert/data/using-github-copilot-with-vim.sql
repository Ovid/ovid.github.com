-- Revert ovid:data/using-github-copilot-with-vim to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'using-github-copilot-with-vim' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
