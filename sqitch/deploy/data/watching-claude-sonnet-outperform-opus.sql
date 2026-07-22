-- Deploy ovid:data/watching-claude-sonnet-outperform-opus to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Watching Claude Sonnet Outperform Opus',
           'watching-claude-sonnet-outperform-opus',
           'We are finally getting to the point where we can write excellent software with AI, but only if you put engineering first. This article explains how.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
