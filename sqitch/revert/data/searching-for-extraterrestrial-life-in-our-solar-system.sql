-- Revert ovid:data/searching-for-extraterrestrial-life-in-our-solar-system to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'searching-for-extraterrestrial-life-in-our-solar-system' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'blog');

COMMIT;
