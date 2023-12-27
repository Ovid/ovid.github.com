-- Revert ovid:data/dont-start-with-microservices to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'dont-start-with-microservices' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
