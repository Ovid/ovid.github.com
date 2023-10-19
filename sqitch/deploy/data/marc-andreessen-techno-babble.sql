-- Deploy ovid:data/marc-andreessen-techno-babble to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Marc Andreessen: Techno Babble',
           'marc-andreessen-techno-babble',
           'By now, if you pay attention to tech, you may have seen Marc Andreessen''s The Techno-Optimist Manifesto. While it''s not all bad, it''s almost breathtaking how thoroughly he misunderstands what''s going on.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
