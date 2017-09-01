/*
Create mt two classes of nodes for my graph: Repos and users
by querying a subset of the massive data dump provided by GHTorrent
*/

-- #1
-- Find repos using Python, and active within past 3 MONTHS (exclude the ridiculous timestamps)
CREATE TABLE active_projects
    SELECT * FROM projects
    WHERE projects.id IN (
        -- Project IDs which had commits in past MONTH
        SELECT DISTINCT(recent_commits.project_id)
        FROM recent_commits
        WHERE recent_commits.created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 3 MONTH)
        AND recent_commits.created_at < '2017-07-01 00:00:00'
        )
    AND projects.id IN (
        -- Only the projects containing Python
        SELECT DISTINCT(project_id)
        FROM project_languages
        WHERE language='Python'
        )
    AND projects.deleted <> 1;

-- #2
-- Find active users associated with the subset of projects found above
CREATE TABLE active_users
SELECT * FROM users
WHERE users.id IN (
    SELECT DISTINCT(active_projects.owner_id)
    FROM active_projects
)
AND users.fake <> 1
AND users.deleted <> 1;


-----------------------------------
-- IN PROGRESS QUERIES --

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

-- Postgres version
COPY (SELECT * FROM active_projects) TO '/home/ubuntu/db/data/active_projects.csv' WITH CSV header;
-- mySQL version
SELECT *
INTO OUTFILE '/home/ubuntu/db/data/active_users.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM active_users;
