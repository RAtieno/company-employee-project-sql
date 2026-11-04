/* ==========================================================
   03_queries.sql
   Company Employee & Project Database (SQL Server / T-SQL)

   Ten business questions, ordered from easier to harder.
   Run 01_create_tables.sql and 02_insert_data.sql first.

   Tables used:
     employees, departments, managers, projects, employee_projects
   ========================================================== */

USE MyDatabase;
GO


/* ----------------------------------------------------------
   Q1: How many employees are in each department, and what
       is the average salary?
   Business use: shows staffing levels and pay differences
   between departments.
   Skills: JOIN, GROUP BY, aggregate functions
   ---------------------------------------------------------- */
SELECT d.dept_name,
       COUNT(*)                AS headcount,
       ROUND(AVG(e.salary), 0) AS avg_salary
FROM dbo.employees e
JOIN dbo.departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY headcount DESC;
GO


/* ----------------------------------------------------------
   Q2: Which employees earn more than their department's
       average salary?
   Business use: helps spot pay outliers within a department.
   Skills: CTE, JOIN
   Note: AVG(salary * 1.0) avoids integer rounding.
   ---------------------------------------------------------- */
WITH dept_avg AS (
    SELECT dept_id, AVG(salary * 1.0) AS avg_salary
    FROM dbo.employees
    GROUP BY dept_id
)
SELECT e.emp_id, e.first_name, e.last_name, d.dept_name,
       e.salary, ROUND(a.avg_salary, 0) AS dept_avg
FROM dbo.employees e
JOIN dept_avg a        ON a.dept_id = e.dept_id
JOIN dbo.departments d ON d.dept_id = e.dept_id
WHERE e.salary > a.avg_salary
ORDER BY d.dept_name, e.salary DESC;
GO


/* ----------------------------------------------------------
   Q3: Who are the top 3 highest-paid employees in each
       department?
   Business use: identifies the highest earners per team for
   pay reviews and budgeting.
   Skills: window function (DENSE_RANK), CTE
   Note: DENSE_RANK keeps tied salaries at the same rank
   without skipping numbers. Compare with RANK and ROW_NUMBER.
   ---------------------------------------------------------- */
WITH ranked AS (
    SELECT e.emp_id, e.first_name, e.last_name, e.salary, d.dept_name,
           DENSE_RANK() OVER (PARTITION BY e.dept_id
                              ORDER BY e.salary DESC) AS salary_rank
    FROM dbo.employees e
    JOIN dbo.departments d ON d.dept_id = e.dept_id
)
SELECT dept_name, salary_rank, first_name, last_name, salary
FROM ranked
WHERE salary_rank <= 3
ORDER BY dept_name, salary_rank;
GO


/* ----------------------------------------------------------
   Q4: Which projects have no employees assigned?
   Business use: flags projects with no resourcing.
   Skills: LEFT JOIN, NULL check
   ---------------------------------------------------------- */
SELECT p.proj_id, p.project_name, p.status, p.start_date
FROM dbo.projects p
LEFT JOIN dbo.employee_projects ep ON ep.proj_id = p.proj_id
WHERE ep.emp_id IS NULL
ORDER BY p.proj_id;
GO


/* ----------------------------------------------------------
   Q5: Which employees are overallocated (more than 40 hours
       per week across all their projects)?
   Business use: flags burnout risk and resourcing problems.
   Skills: GROUP BY, HAVING
   Assumption: hours_allocated is hours per week.
   ---------------------------------------------------------- */
SELECT e.emp_id, e.first_name, e.last_name,
       COUNT(*)                AS project_count,
       SUM(ep.hours_allocated) AS total_weekly_hours
FROM dbo.employees e
JOIN dbo.employee_projects ep ON ep.emp_id = e.emp_id
GROUP BY e.emp_id, e.first_name, e.last_name
HAVING SUM(ep.hours_allocated) > 40
ORDER BY total_weekly_hours DESC;
GO


/* ----------------------------------------------------------
   Q6: What is the budget per team member for each project?
   Business use: compares how much funding each project has
   relative to its team size.
   Skills: LEFT JOIN, NULLIF (avoids divide-by-zero)
   Note: unstaffed projects show NULL instead of an error.
   ---------------------------------------------------------- */
SELECT p.proj_id, p.project_name, p.status, p.budget,
       COUNT(ep.emp_id)                       AS team_size,
       p.budget / NULLIF(COUNT(ep.emp_id), 0) AS budget_per_member
FROM dbo.projects p
LEFT JOIN dbo.employee_projects ep ON ep.proj_id = p.proj_id
GROUP BY p.proj_id, p.project_name, p.status, p.budget
ORDER BY budget_per_member DESC;
GO


/* ----------------------------------------------------------
   Q7: Which manager has the largest team?
   Business use: shows span of control and workload by manager.
   Skills: multi-table JOIN, aggregation
   Tip: use SELECT TOP 1 WITH TIES to return only the leader(s).
   ---------------------------------------------------------- */
SELECT m.manager_id,
       m.first_name + ' ' + m.last_name AS manager,
       d.dept_name,
       COUNT(e.emp_id)                  AS team_size
FROM dbo.managers m
JOIN dbo.departments d    ON d.dept_id = m.dept_id
LEFT JOIN dbo.employees e ON e.manager_id = m.manager_id
GROUP BY m.manager_id, m.first_name, m.last_name, d.dept_name
ORDER BY team_size DESC;
GO


/* ----------------------------------------------------------
   Q8: What is the average employee tenure (in years) by
       department?
   Business use: indicates retention and experience levels.
   Skills: date functions (DATEDIFF, GETDATE)
   Note: months / 12.0 is more accurate than DATEDIFF(YEAR),
   which only counts calendar-year boundaries.
   ---------------------------------------------------------- */
SELECT d.dept_name,
       ROUND(AVG(DATEDIFF(MONTH, e.hire_date, GETDATE()) / 12.0), 1) AS avg_tenure_years
FROM dbo.employees e
JOIN dbo.departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY avg_tenure_years DESC;
GO


/* ----------------------------------------------------------
   Q9: How many people were hired each year, with a running
       total?
   Business use: shows hiring trends and company growth.
   Skills: CTE, window SUM with a running frame
   ---------------------------------------------------------- */
WITH yearly AS (
    SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS hires
    FROM dbo.employees
    GROUP BY YEAR(hire_date)
)
SELECT hire_year,
       hires,
       SUM(hires) OVER (ORDER BY hire_year ROWS UNBOUNDED PRECEDING) AS running_total
FROM yearly
ORDER BY hire_year;
GO


/* ----------------------------------------------------------
   Q10: Which employees work on more than one project, and
        what are those projects?
   Business use: shows who is spread across several projects.
   Skills: JOIN, HAVING, STRING_AGG
   Note: STRING_AGG requires SQL Server 2017 or later.
   ---------------------------------------------------------- */
SELECT e.emp_id, e.first_name, e.last_name,
       COUNT(*)                         AS project_count,
       STRING_AGG(p.project_name, ', ')  AS projects
FROM dbo.employees e
JOIN dbo.employee_projects ep ON ep.emp_id = e.emp_id
JOIN dbo.projects p           ON p.proj_id = ep.proj_id
GROUP BY e.emp_id, e.first_name, e.last_name
HAVING COUNT(*) > 1
ORDER BY project_count DESC;
GO