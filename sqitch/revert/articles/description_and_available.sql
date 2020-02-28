-- Revert ovid:articles/description_and_available from sqlite

-- foreign keys were not enabled for db/ovid.db
BEGIN;

    --
    -- Creating our new table
    -- Manually change the table here, such as adding a new column
    -- 
    CREATE TABLE articles_1582879379 (
            article_id      INTEGER PRIMARY KEY,
            title           VARCHAR(100) NOT NULL,
            slug            VARCHAR(100) NOT NULL,
            article_type_id INTEGER      NOT NULL,
            sort_order      INTEGER      NOT NULL,
            created         TEXT         NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE (article_type_id, sort_order),
            UNIQUE (article_type_id, title),
            UNIQUE (article_type_id, slug)
        );


    --
    -- Manually alter each of these insert statements as needed
    --
    INSERT INTO articles_1582879379 VALUES(1,'Case Study: 500 TPS','project-500',1,20,'2019-09-18 05:36:05');
    INSERT INTO articles_1582879379 VALUES(2,'Moving from Oracle to PostgreSQL','moving-from-oracle-to-postgresql',1,19,'2019-07-20 09:35:55');
    INSERT INTO articles_1582879379 VALUES(3,'Managing a Remote Team','managing-a-remote-team',1,18,'2019-07-17 10:01:24');
    INSERT INTO articles_1582879379 VALUES(4,'Project Management in Three Numbers','project-management-in-three-numbers',1,17,'2019-06-05 10:27:30');
    INSERT INTO articles_1582879379 VALUES(5,'Alan Kay and Missing Messages (a follow-up)','alan-kay-and-missing-messages-a-follow-up',1,16,'2019-05-22 09:54:46');
    INSERT INTO articles_1582879379 VALUES(6,'Alan Kay and OO Programming','alan-kay-and-oo-programming',1,15,'2019-05-17 13:29:22');
    INSERT INTO articles_1582879379 VALUES(7,'The Worst Job Offer','the-worst-job-offer',1,14,'2019-05-17 09:40:47');
    INSERT INTO articles_1582879379 VALUES(8,'Software Projects as Used Cars','the-tyranny-of-budgets',1,13,'2019-05-14 16:48:39');
    INSERT INTO articles_1582879379 VALUES(9,'How to Defeat Facebook','how-to-defeat-facebook',1,12,'2019-04-28 10:37:13');
    INSERT INTO articles_1582879379 VALUES(10,'Fixing MVC in Web Applications','fixing-mvc-in-web-applications',1,11,'2019-04-17 11:41:02');
    INSERT INTO articles_1582879379 VALUES(11,'Avoid Common Software Project Mistakes','avoid-common-software-project-mistakes',1,10,'2019-04-11 13:11:11');
    INSERT INTO articles_1582879379 VALUES(12,'Estimating Development Costs is Almost Useless','estimating-development-costs-is-almost-useless',1,9,'2019-02-01 09:04:23');
    INSERT INTO articles_1582879379 VALUES(13,'The Surprises of A/B Testing','the-surprises-of-ab-testing',1,8,'2019-01-22 15:17:36');
    INSERT INTO articles_1582879379 VALUES(14,'GDPR and Bankruptcy','gdpr-and-bankruptcy',1,7,'2018-11-23 12:24:51');
    INSERT INTO articles_1582879379 VALUES(15,'Death by Database','death-by-database',1,6,'2018-09-19 18:34:09');
    INSERT INTO articles_1582879379 VALUES(16,'The Zen of test suites','zen-of-test-suites',1,5,'2018-09-16 23:46:07');
    INSERT INTO articles_1582879379 VALUES(17,'How the database can hurt your startup','how-databases-can-hurt-your-startup',1,4,'2018-09-16 23:16:25');
    INSERT INTO articles_1582879379 VALUES(18,'A simple way to fix legacy code','a-simple-way-to-fix-legacy-code',1,3,'2018-09-16 22:47:29');
    INSERT INTO articles_1582879379 VALUES(19,'When to choose agile','when-to-choose-agile',1,2,'2018-09-16 20:57:22');
    INSERT INTO articles_1582879379 VALUES(20,'When going agile can hurt your company','going-agile-can-hurt-your-company',1,1,'2018-09-16 20:57:22');
    INSERT INTO articles_1582879379 VALUES(21,'A Eulogy for My Father','my-father',2,1,'2019-08-01 20:57:22');
    INSERT INTO articles_1582879379 VALUES(22,'Missing Siblings?','missing-siblings',2,2,'2019-11-01 20:57:22');
    INSERT INTO articles_1582879379 VALUES(23,'Why is zero factorial equal to one?','why-is-zero-factorial-equal-to-one',2,3,'2019-12-01 20:57:22');
    INSERT INTO articles_1582879379 VALUES(24,'Babylonian Numbers for 8-Year Olds','babylonian-numbers-for-8-year-olds',2,21,'2019-12-28 11:14:10');
    INSERT INTO articles_1582879379 VALUES(25,'Will It Rain Tomorrow?','will-it-rain-tomorrow',2,22,'2019-12-28 13:33:07');
    INSERT INTO articles_1582879379 VALUES(26,'Moose "has" a Problem','moose-has-a-problem',2,23,'2019-12-31 10:05:27');
    INSERT INTO articles_1582879379 VALUES(27,'Automated Software Standards','automated-software-standards',1,24,'2020-01-05 10:10:50');
    INSERT INTO articles_1582879379 VALUES(28,'Database Design Standards','database-design-standards',1,25,'2020-01-07 16:46:48');


    DROP TABLE articles;
    ALTER TABLE articles_1582879379 RENAME TO articles;

COMMIT;

