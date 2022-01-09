-- Revert ovid:data/are-microservices-the-next-phase-of-object-oriented-programming to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'are-microservices-the-next-phase-of-object-oriented-programming' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
