# EDA using SQL (mySQL)

#### 6.1 million projects that contain Python
`SELECT COUNT(*) FROM project_languages WHERE language='Python';`
+----------+
| COUNT(*) |
+----------+
|  6109358 |
+----------+

#### 160k active projects (have been committed to in past year, involve Python as MAIN language, and have not been deleted)
```
SELECT * FROM projects
WHERE projects.id IN
    (-- Project IDs which had commits in past MONTH
        SELECT DISTINCT(recent_commits.project_id)
        FROM recent_commits
        WHERE recent_commits.created_at > DATE_SUB('2017-07-01 00:00:00', INTERVAL 1 YEAR)
        AND recent_commits.created_at < '2017-07-01 00:00:00'
    )
AND projects.language = 'Python'
AND projects.deleted <> 1;
```

#### Oldest Python repo that's still active
`SELECT id, name, url, created_at FROM active_projects ORDER BY created_at LIMIT 1;`
+--------+---------+------------------------------------------------+---------------------+
| id     | name    | url                                            | created_at          |
+--------+---------+------------------------------------------------+---------------------+
| 447228 | pysolar | https://api.github.com/repos/pingswept/pysolar | 2008-03-01 23:35:48 |
+--------+---------+------------------------------------------------+---------------------+
https://github.com/pingswept/pysolar  
The latest commit on this repo was 17 days ago as of 2017-08-31

#### 113k users that have been involved in an active project as described above
```
SELECT * FROM users
WHERE users.id IN (
    SELECT DISTINCT(active_projects_1MONTH.owner_id)
    FROM active_projects_1MONTH
)
AND users.fake <> 1
AND users.deleted <> 1;
```
