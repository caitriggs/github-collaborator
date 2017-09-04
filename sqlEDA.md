# EDA using SQL (mySQL)

#### Some aggregative counts for number of rows in each table
```
SELECT table_name, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'github';
```

#### 4 million projects that contain Python
`SELECT COUNT(DISTINCT(project_id)) FROM project_languages WHERE language='Python';`
+-----------------------------+
| COUNT(DISTINCT(project_id)) |
+-----------------------------+
|                     4013856 |
+-----------------------------+

#### 215K active projects (have been committed to in past 3 months, involve Python, and have not been deleted)
```
SELECT COUNT(*) FROM projects
WHERE projects.id IN (
    -- Project IDs which had commits in past 3 MONTHS
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
```

#### Of those active projects containing Python, the repo counts for top 10 main language used are:
```
SELECT language, COUNT(language) AS repo_count
FROM active_projects
GROUP BY language ORDER BY repo_count DESC;
```
+--------------------------+------------+
| language                 | repo_count |
+--------------------------+------------+
| Python                   |     116996 |
| C++                      |      14961 |
| JavaScript               |      11593 |
| C                        |      10747 |
| HTML                     |       6968 |
| Java                     |       6209 |
| Shell                    |       5972 |
| Jupyter Notebook         |       5057 |
| CSS                      |       2639 |
| VimL                     |       2487 |

#### 158K users that have been involved in an active project as described above
```
SELECT * FROM users
WHERE users.id IN (
    SELECT DISTINCT(active_projects.owner_id)
    FROM active_projects
)
AND users.fake <> 1
AND users.deleted <> 1;
```

#### 336 languages used in repos across github
`SELECT COUNT(DISTINCT(language)) FROM project_languages;`  
where the language with the most bytes across all of GitHub is C
```
SELECT language, SUM(bytes) AS bytes_total
FROM project_languages
GROUP BY language ORDER BY bytes_total DESC;
```
Top 10 Languages used by bytes (not recent popularity)
+--------------------------+----------------+
| language                 | bytes_total    |
+--------------------------+----------------+
| c                        | 33745563301157 |
| javascript               |  8772914743744 |
| c++                      |  7387335707459 |
| java                     |  5537591624711 |
| html                     |  4195420715203 |
| php                      |  4000175406066 |
| python                   |  2524272458768 |
| c#                       |  1898655478016 |
| css                      |  1311112843761 |
| assembly                 |   895289524102 |

#### A language listed as "minid" showed up as having a whopping total of 41 bytes of code in all of GitHub. The language listed with the least amount of code found in only a single repo on GitHub:
```
SELECT projects.name, projects.url, users.id, users.login
FROM users
JOIN projects ON projects.owner_id = users.id
WHERE projects.id IN (
    SELECT DISTINCT(projects.id) FROM projects
    JOIN project_languages ON projects.id = project_languages.project_id
    WHERE project_languages.language = 'minid'
    );
```
+-------------+-----------------------------------------------------+----------+------------+
| name        | url                                                 | id       | login      |
+-------------+-----------------------------------------------------+----------+------------+
| rainbowlang | https://api.github.com/repos/johntiger1/rainbowlang | 13226675 | johntiger1 |
+-------------+-----------------------------------------------------+----------+------------+
It came from a repo called "rainbowlang", the repo which has "All the languages. All night long."

#### Oldest mainly Python repo that's still active
```
SELECT id, name, url, created_at
FROM active_projects
WHERE language='Python'
ORDER BY created_at LIMIT 1;
```
+--------+---------+------------------------------------------------+---------------------+
| id     | name    | url                                            | created_at          |
+--------+---------+------------------------------------------------+---------------------+
| 447228 | pysolar | https://api.github.com/repos/pingswept/pysolar | 2008-03-01 23:35:48 |
+--------+---------+------------------------------------------------+---------------------+
https://github.com/pingswept/pysolar  

### Oldest repo that contains Python that's still active_users
```
SELECT id, name, url, created_at
FROM active_projects
ORDER BY created_at LIMIT 1;
```
Mostly written in Ruby
+-------+----------+------------------------------------------------+---------------------+
| id    | name     | url                                            | created_at          |
+-------+----------+------------------------------------------------+---------------------+
| 12031 | rubinius | https://api.github.com/repos/rubinius/rubinius | 2008-01-12 16:46:52 |
+-------+----------+------------------------------------------------+---------------------+
https://github.com/rubinius/rubinius
