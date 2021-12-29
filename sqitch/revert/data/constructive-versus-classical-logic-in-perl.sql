-- Revert ovid:data/constructive-versus-classical-logic-in-perl to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'constructive-versus-classical-logic-in-perl' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
