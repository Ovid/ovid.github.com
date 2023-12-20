-- Revert ovid:data/microservices-pros-and-cons to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'microservices-pros-and-cons' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
