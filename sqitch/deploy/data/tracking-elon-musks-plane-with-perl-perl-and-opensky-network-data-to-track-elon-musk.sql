-- Deploy ovid:data/tracking-elon-musks-plane-with-perl-perl-and-opensky-network-data-to-track-elon-musk to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Tracking Elon Musk''s Plane with Perl',
           'tracking-elon-musks-plane-with-perl',
           'Using Perl and OpenSky Network data to track Elon Musk''s plane',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
