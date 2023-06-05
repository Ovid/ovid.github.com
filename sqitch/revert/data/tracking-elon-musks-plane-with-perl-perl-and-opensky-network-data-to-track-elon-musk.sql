-- Revert ovid:data/tracking-elon-musks-plane-with-perl-perl-and-opensky-network-data-to-track-elon-musk to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'tracking-elon-musks-plane-with-perl-perl-and-opensky-network-data-to-track-elon-musk' AND article_type_id = (SELECT article_type_id FROM article_types WHERE type = 'article');

COMMIT;
