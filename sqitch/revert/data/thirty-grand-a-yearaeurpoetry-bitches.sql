-- Revert ovid:data/thirty-grand-a-yearaeurpoetry-bitches to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'thirty-grand-a-year-poetry-bitches' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
