-- Deploy ovid:data/be-skeptical-of-ai-studies to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Be Skeptical of AI Studies',
           'be-skeptical-of-ai-studies',
           'A new study that Ars Technica reported on found that AI coding is not generating more value because reviewing the code has become the bottleneck. Even if the study''s findings are correct, the limitations of the study make its conclusions useless.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
