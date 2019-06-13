-- Deploy ovid:data/initial_articles to sqlite

BEGIN;

    INSERT INTO articles (title, directory, slug, created) VALUES ('Project Management in Three Numbers', '/articles/', 'project-management-in-three-numbers', '2019-06-05 10:27:30');
    INSERT INTO articles (title, directory, slug, created) VALUES ('How to Defeat Facebook', '/articles/', 'how-to-defeat-facebook', '2019-04-28 10:37:13');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Alan Kay and Missing Messages (a follow-up)', '/articles/', 'alan-kay-and-missing-messages-a-follow-up', '2019-05-22 09:54:46');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Alan Kay and OO Programming', '/articles/', 'alan-kay-and-oo-programming', '2019-05-17 13:29:22');
    INSERT INTO articles (title, directory, slug, created) VALUES ('The Worst Job Offer', '/articles/', 'the-worst-job-offer', '2019-05-17 09:40:47');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Software Projects as Used Cars', '/articles/', 'the-tyranny-of-budgets', '2019-05-14 16:48:39');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Fixing MVC in Web Applications', '/articles/', 'fixing-mvc-in-web-applications', '2019-04-17 11:41:02');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Avoid Common Software Project Mistakes', '/articles/', 'avoid-common-software-project-mistakes', '2019-04-11 13:11:11');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Estimating Development Costs is Almost Useless', '/articles/', 'estimating-development-costs-is-almost-useless', '2019-02-01 09:04:23');
    INSERT INTO articles (title, directory, slug, created) VALUES ('The Surprises of A/B Testing', '/articles/', 'the-surprises-of-ab-testing', '2019-01-22 15:17:36');
    INSERT INTO articles (title, directory, slug, created) VALUES ('GDPR and Bankruptcy', '/articles/', 'gdpr-and-bankruptcy', '2018-11-23 12:24:51');
    INSERT INTO articles (title, directory, slug, created) VALUES ('Death by Database', '/articles/', 'death-by-database', '2018-09-19 18:34:09');
    INSERT INTO articles (title, directory, slug, created) VALUES ('The Zen of test suites', '/articles/', 'zen-of-test-suites', '2018-09-16 23:46:07');
    INSERT INTO articles (title, directory, slug, created) VALUES ('How the database can hurt your startup', '/articles/', 'how-databases-can-hurt-your-startup', '2018-09-16 23:16:25');
    INSERT INTO articles (title, directory, slug, created) VALUES ('A simple way to fix legacy code', '/articles/', 'a-simple-way-to-fix-legacy-code', '2018-09-16 22:47:29');
    INSERT INTO articles (title, directory, slug, created) VALUES ('When to choose agile', '/articles/', 'when-to-choose-agile', '2018-09-16 20:57:22');
    INSERT INTO articles (title, directory, slug, created) VALUES ('When going agile can hurt your company', '/articles/', 'going-agile-can-hurt-your-company', '2018-09-16 20:57:22');

COMMIT;
