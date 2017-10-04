/*
Create my two classes of nodes for my graph: Repos and Users
Or for ALS collaborative filtering model, my User-Item ratings set
by querying a subset of the data dump provided by GHTorrent
*/


-- #1
-- Find repos using Python, and active within past 3 MONTHS (exclude the ridiculous timestamps)
CREATE TABLE active_projects
    SELECT COUNT(*) FROM projects
    WHERE projects.id IN (
        -- Project IDs which had commits in past MONTH
        SELECT DISTINCT(recent_commits.project_id)
        FROM recent_commits
        WHERE recent_commits.created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 3 MONTH)
        AND recent_commits.created_at < '2017-07-01 00:00:00'
        )
    OR projects.id IN (
        -- Explicitly add classmates to dataset
        SELECT DISTINCT(projects.id)
        FROM projects
        WHERE projects.owner_id IN (
            7271611, 35576250, 3384558, 10050726, 5159082, 2317156, 490051, 33810752, 3287152)
        )
    AND projects.id IN (
        -- Only the projects containing Python
        SELECT DISTINCT(project_id)
        FROM project_languages
        WHERE language='Python'
        )
    AND projects.deleted <> 1;

-- #2
-- Find active users associated with the subset of projects found above.
/* there are many bot users which GHTorrent has already conviently marked as being "fake". We only
want real users who can interact with the app to get recommendations */
CREATE TABLE active_users
    SELECT * FROM users
    WHERE users.id IN (
        SELECT DISTINCT(active_projects.owner_id)
        FROM active_projects
    )
    AND users.fake <> 1
    AND users.deleted <> 1;

-- #3
-- Subset Starred Active Repos
CREATE TABLE active_stars
SELECT * FROM watchers
WHERE watchers.repo_id IN (
SELECT DISTINCT(active_projects.id)
FROM active_projects
);

-- #4
-- Subset Followers of Active users
CREATE TABLE active_follows
SELECT * FROM followers
WHERE followers.user_id IN (
SELECT DISTINCT(active_users.id)
FROM active_users
);

--------------------------------
-- RESUBSET BASED ON ACTIVE USERS and grab all their star and repos --
-- #1A Active users
CREATE TABLE subset_users
SELECT * FROM users
WHERE users.id IN (
    SELECT DISTINCT(user_to_stars.user_id)
    FROM user_to_stars
    WHERE num_repos_starred >= 5
)
AND users.id IN (
    SELECT DISTINCT(user_to_projs.owner_id)
    FROM user_to_projs
    WHERE num_repos_owned >= 1
    AND num_repos_owned < 50
)
AND users.fake <> 1
AND users.deleted <> 1;

-- #1B Select 100k random samples from that subset
CREATE TABLE new_subset_users
SELECT * FROM subset_users
ORDER BY RAND()
LIMIT 50000;

-- #1C Add specific users into my random_users TABLE
INSERT INTO new_subset_users
SELECT * FROM users
WHERE id IN (
    7271611, 35576250, 3384558, 10050726, 5159082, 2317156, 490051, 33810752, 3287152
);

-- #2 Repos starred by a subset user
CREATE TABLE new_subset_stars
SELECT * FROM watchers
WHERE watchers.user_id IN (
    SELECT DISTINCT(new_subset_users.id)
    FROM new_subset_users
)
AND watchers.repo_id IN (
    SELECT DISTINCT(projects.id)
    FROM projects
    WHERE projects.deleted <> 1
);

-- #3 Repos either owned by a subset user or repos starred by a subset user
CREATE TABLE new_subset_repos
SELECT * FROM projects
WHERE projects.owner_id IN (
    SELECT DISTINCT(new_subset_users.id)
    FROM new_subset_users)
OR projects.id IN (
    SELECT DISTINCT(new_subset_stars.repo_id)
    FROM new_subset_stars);

-- Just to make sure deleted repos dont show up in recommendations
DELETE FROM new_subset_repos WHERE deleted = 1;

-- FINAL QUERY --
/*
In the final set of data used for ALS collaborative filtering, I used all
users not deleted & all projects not deleted and aggregated their info by:
- stars/forks
- commits per repo (including forked-from repos as another user-item rating)
*/
----------------------------------
-- Find commits per repo


CREATE TABLE active_repo_commits
SELECT * FROM commits_per_repo
WHERE commits_per_repo.project_id IN (
    SELECT DISTINCT(projects.id) FROM projects
    WHERE projects.deleted <> 1
);


-----------------------------------
-- IN PROGRESS QUERIES --

-- Some aggregative counts for number of rows in each table
SELECT table_name, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'github';

-- Min/Max create and update dates from for active projects using python
SELECT MIN(created_at) as c_from_date, MAX(created_at) as c_to_date,
        MIN(updated_at) as u_from_date, MAX(updated_at) as u_to_date
FROM (
    -- Create joined table of current projects created in June or updated within year
    SELECT t.project_id, projects.owner_id, t.language, projects.language as main_lang,
        t.python_bytes, projects.url, projects.name, projects.description,
        projects.forked_from, projects.deleted, projects.updated_at, projects.created_at
        FROM (
            -- Only the projects containing Python
            SELECT project_id, language, bytes as python_bytes
            FROM project_languages
            WHERE language='Python') t
    LEFT JOIN projects ON t.project_id = projects.id
        -- Projects either created in June 2017 OR updated within past year
        WHERE projects.created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 1 MONTH)
        OR projects.updated_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 1 YEAR)
        AND projects.deleted <> 1
    ) AS z;

--
SELECT users.id, active_projects.owner_id, active_projects.project_id,
active_projects.forked_from, active_projects.created_at
FROM users
INNER JOIN active_projects ON users.id = active_projects.owner_id
WHERE users.fake <> 1 AND users.deleted <> 1;

-- Find the most recent commit for each project and return the project_id
SELECT t1.project_id, t1.created_at
FROM recent_commits t1
WHERE t1.created_at = (SELECT MAX(t2.created_at)
                 FROM recent_commits t2
                 WHERE t2.project_id = t1.project_id);

-- Grab just the commits created in the last 3 months ~63 million
CREATE TABLE ghtorrent_restore.recent_commits
    SELECT * FROM commits
    WHERE commits.created_at > DATE_SUB('2017-07-01', INTERVAL 3 MONTH);

-- Grab most recent commit from repos and return active project ids
SELECT * FROM projects
WHERE projects.id IN (
    -- Project IDs which had commits in past MONTH
    SELECT DISTINCT(recent_commits.project_id)
    FROM recent_commits
    WHERE recent_commits.created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 6 MONTH)
    AND recent_commits.created_at < '2017-07-01 00:00:00'
    )
AND projects.id IN (
    -- Only the projects containing Python
    SELECT DISTINCT(project_id)
    FROM project_languages
    WHERE language='Python'
    )
AND projects.deleted <> 1;


SELECT active_projects.id, GROUP_CONCAT(DISTINCT project_languages.language) AS languages
FROM active_projects
INNER JOIN project_languages ON active_projects.id = project_languages.project_id
GROUP BY active_projects.id, project_languages.language
limit 20;


SELECT active_users.login, active_projects.name as repo_name
INTO OUTFILE '/home/ubuntu/db/data/active_users_repos.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM active_projects
JOIN active_users ON active_users.id = active_projects.owner_id;


-- PostgresSQL version
COPY (SELECT * FROM active_projects) TO '/home/ubuntu/db/data/active_projects.csv' WITH CSV header;

-- Replace
UPDATE active_projects SET description = replace(description, '\t', ' ');

-- CREATE CSV SUBSET FILES
-- mySQL version
// REPOS
SELECT id, url, owner_id, name, language, created_at, forked_from
INTO OUTFILE '/home/ubuntu/db/data/new_subset_repos.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM new_subset_repos;

/* Add headers REPOS
sed -i '1i id\turl\towner_id\tname\tlanguage\tcreated_at\tforked_from' new_subset_repos.csv
*/

// USERS
SELECT id, login, company, created_at, type, country_code, state, city, location
INTO OUTFILE '/home/ubuntu/db/data/new_subset_users.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM new_subset_users;

/* Add headers USERS
sed -i '1i id\tlogin\tcompany\tcreated_at\ttype\tcountry_code\tstate\tcity\tlocation' new_subset_users.csv
*/

// STARS
SELECT *
INTO OUTFILE '/home/ubuntu/db/data/new_subset_stars.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM new_subset_stars;

/* Add headers STARS
sed -i '1i repo_id\tuser_id\tcreated_at' new_subset_stars.csv
*/

// FOLLOWS
SELECT *
INTO OUTFILE '/home/ubuntu/db/data/active_follows.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM active_follows;

/* Add headers FOLLOWS
sed -i '1i user_id\tfollower_id\tcreated_at' active_follows.csv
*/

// COMMITS
SELECT *
INTO OUTFILE '/home/ubuntu/db/data/commits_per_repo.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM final_commits_per_repo;

/* Add headers COMMITS
sed -i '1i repo_id\tuser_id\tcommits' commits_per_repo.csv
*/

// USER-REPO LOOKUP
SELECT *
INTO OUTFILE '/home/ubuntu/db/data/user_repo_lookup.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM user_repo_lookup_table;

/* Add headers COMMITS
sed -i '1i user_id\tlogin\trepo_id\tforked_from\trepo_name\turl' user_repo_lookup.csv
*/

// STARS PER REPO
SELECT *
INTO OUTFILE '/home/ubuntu/db/data/stars_per_repo.csv'
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM repo_stars;

/* Add headers STARS PER REPO
sed -i '1i repo_id\tstars' stars_per_repo.csv
*/

-- Classmate usernames and ids
SELECT id, login FROM users WHERE login IN
('caitriggs', 'ayadlin', 'sadahanu', 'Brionnic', 'NeverForged', 'gavin-peterkin',
    'mileserickson', 'jackbenn', 'jfomhover');
    +----------+----------------+
    | id       | login          |
    +----------+----------------+
    |  7271611 | ayadlin        |
    | 35576250 | Brionnic       |
    |  3384558 | caitriggs      |
    | 10050726 | gavin-peterkin |
    |  5159082 | jackbenn       |
    |  2317156 | jfomhover      |
    |   490051 | mileserickson  |
    | 33810752 | NeverForged    |
    |  3287152 | sadahanu       |
    +----------+----------------+
    7271611, 35576250, 3384558, 10050726, 5159082, 2317156, 490051, 33810752, 3287152

 -- Count number of repos a user has starred
CREATE TABLE user_to_stars
SELECT watchers.user_id, COUNT(*) AS num_repos_starred
FROM watchers
GROUP BY watchers.user_id;

-- Count number of repos a user owns
CREATE TABLE user_to_projs
SELECT projects.owner_id, COUNT(*) AS num_repos_owned
FROM projects
GROUP BY projects.owner_id;

-- Create a table of recent stars (past 3 months)
CREATE TABLE recent_stars
SELECT * FROM watchers
WHERE created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 3 MONTH);


SELECT COUNT(*) FROM users
WHERE users.id IN (
    SELECT DISTINCT(user_to_stars.user_id)
    FROM user_to_stars
    WHERE num_repos_starred >= 5
    AND num_repos_starred < 500
)
AND users.id IN (
    SELECT DISTINCT(user_to_projs.owner_id)
    FROM user_to_projs
    WHERE num_repos_owned >= 5
    AND num_repos_owned < 50
)
AND users.fake <> 1
AND users.deleted <> 1;

-- RANDOMLY SAMPLE 100k users
select * from users
order by rand()
limit 100000;

/*
AND users.id IN (
    SELECT DISTINCT(recent_stars.user_id)
    FROM recent_stars
    WHERE created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 3 MONTH)
)
*/

CREATE TABLE resubset_active_repos
SELECT COUNT(*) FROM projects
WHERE projects.owner_id IN (
    SELECT DISTINCT(random_users.id)
    FROM random_users
);

-- Add specific users into my random_users TABLE
INSERT INTO random_users
SELECT * FROM users
WHERE id IN (
    7271611, 35576250, 3384558, 10050726, 5159082, 2317156, 490051, 33810752, 3287152
);

-- Check which user ids are duplicates
SELECT new_subset_users.id, COUNT(*) AS count_id
FROM new_subset_users
GROUP BY new_subset_users.id
ORDER BY count_id DESC
LIMIT 20;

-- Delete the uplicate IDs
delete from new_subset_users
where id = 490051
limit 1;


----------------- NUMBER OF COMMITS PER REPO ---------------------

CREATE TABLE active_repo_commits
SELECT * FROM commits_per_repo
WHERE commits_per_repo.project_id IN (
    SELECT DISTINCT(projects.id) FROM projects
    WHERE projects.deleted <> 1
);

CREATE TABLE commits_per_fork
SELECT * FROM
    (SELECT projects.forked_from, active_repo_commits.committer_id, active_repo_commits.commits
    FROM projects
    INNER JOIN active_repo_commits ON projects.id = active_repo_commits.project_id AND
        projects.owner_id = active_repo_commits.committer_id) AS a
WHERE a.forked_from IS NOT NULL;

-- Find if any projects or forked projects are deleted
SELECT COUNT(*) FROM commits_per_fork
WHERE commits_per_fork.forked_from IN (
    SELECT DISTINCT(projects.id)
    FROM projects
    WHERE projects.id = 1
);

-- Concat the commits_per_fork onto the active_repo_commits TABLE
ALTER TABLE commits_per_fork CHANGE forked_from project_id int(11);

-- Union two forks and repos tables
CREATE TABLE final_commits_per_repo
SELECT * FROM (
    SELECT * FROM active_repo_commits
    UNION ALL
    SELECT * FROM commits_per_fork) AS a
WHERE commits > 5;

-- Create User-Repo Lookup Table
CREATE TABLE user_repo_lookup_table
SELECT users.id AS user_id, users.login,
projects.id AS repo_id, projects.forked_from AS forked_from, projects.name AS repo_name, projects.url
FROM projects
INNER JOIN users ON projects.owner_id = users.id;
