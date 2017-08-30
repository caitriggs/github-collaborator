-- Some aggregative counts for number of rows in each table
SELECT table_name, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'ghtorrent_restore';

-- Select only projects containing Python
SELECT project_id FROM project_languages
WHERE language = 'Python';

-- Select only projects updated within last 6 months
SELECT id FROM projects
WHERE updated_at > DATE_SUB(now(), INTERVAL 6 MONTH)
AND deleted <> 1;

-- Check if field is unique
select sha, count(*) as count
from commits
group by sha
having count(*) > 1

-- Randomly sample 1% of table
