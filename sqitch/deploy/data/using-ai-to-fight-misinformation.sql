-- Deploy ovid:data/using-ai-to-fight-misinformation to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Using AI to Fight Misinformation',
           'using-ai-to-fight-misinformation',
           'Tired of people sending you pseudo-science articles, or ''opinion'' pieces by biased journalists? AI can actually help.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
