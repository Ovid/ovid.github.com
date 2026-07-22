-- Revert ovid:data/watching-claude-sonnet-outperform-opus to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'watching-claude-sonnet-outperform-opus' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
