
-- Find repos using Python, and active within past year
CREATE TABLE active_projects SELECT * FROM (
    SELECT t.project_id, projects.owner_id, t.language, projects.language as main_lang,
        t.python_bytes, projects.url, projects.name, projects.description,
        projects.forked_from, projects.deleted, projects.updated_at, projects.created_at
        FROM (
            SELECT project_id, language, bytes as python_bytes
            FROM project_languages
            WHERE language='Python') t
    LEFT JOIN projects ON t.project_id = projects.id
        WHERE projects.updated_at > DATE_SUB('2017-07-01', INTERVAL 1 YEAR)
        OR projects.created_at > DATE_SUB('2017-07-01', INTERVAL 1 MONTH)
        AND projects.deleted <> 1
    ) z;

SELECT MIN(created_at) as from_date, MAX(created_at) as to_date FROM active_projects;

SELECT MIN(created_at) as c_from_date, MAX(created_at) as c_to_date,
        MIN(updated_at) as u_from_date, MAX(updated_at) as u_to_date
FROM (
    SELECT t.project_id, projects.owner_id, t.language, projects.language as main_lang,
        t.python_bytes, projects.url, projects.name, projects.description,
        projects.forked_from, projects.deleted, projects.updated_at, projects.created_at
        FROM (
            SELECT project_id, language, bytes as python_bytes
            FROM project_languages
            WHERE language='Python') t
    LEFT JOIN projects ON t.project_id = projects.id
        WHERE ( projects.created_at > DATE_SUB('2017-07-01', INTERVAL 1 MONTH)
        OR projects.updated_at > DATE_SUB('2017-07-01', INTERVAL 1 YEAR) )
        AND projects.deleted <> 1) AS z;
