-- Deploy ovid:data/language-design-consistency to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Language Design Consistency',
           'language-design-consistency',
           'Consistency can be a hallmark of great language design. My Corinna OO project for Perl falls short of this.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
