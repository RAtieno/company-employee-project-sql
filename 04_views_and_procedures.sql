/* ==========================================================
   05_views_and_procedures.sql
   Company Employee & Project Database (SQL Server / T-SQL)

   Reusable views and stored procedures built on top of the
   schema. Run after 01_create_tables.sql and 02_insert_data.sql.

   Views
     vw_employee_details      Employee profile with department and manager
     vw_project_staffing      Team size, hours, and lead for each project
     vw_employee_workload     Weekly hours per employee with a workload flag

   Stored procedures
     usp_get_department_report        Employees and projects for one department
     usp_assign_employee_to_project   Safely assigns an employee to a project
   ========================================================== */

USE MyDatabase;
GO


/* ==========================================================
   VIEWS
   ========================================================== */

/* ----------------------------------------------------------
   vw_employee_details
   One row per employee with the joins already done.
   ---------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_employee_details
AS
SELECT e.emp_id,
       e.first_name + ' ' + e.last_name                           AS employee_name,
       e.email,
       e.job_title,
       d.dept_name,
       e.salary,
       e.hire_date,
       ROUND(DATEDIFF(MONTH, e.hire_date, GETDATE()) / 12.0, 1)    AS tenure_years,
       m.first_name + ' ' + m.last_name                           AS manager_name
FROM dbo.employees e
JOIN dbo.departments d      ON d.dept_id = e.dept_id
LEFT JOIN dbo.managers m    ON m.manager_id = e.manager_id;
GO


/* ----------------------------------------------------------
   vw_project_staffing
   One row per project, including projects with no staff.
   Assumes each project has at most one 'Project Lead'.
   ---------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_project_staffing
AS
SELECT p.proj_id,
       p.project_name,
       p.status,
       p.start_date,
       p.end_date,
       p.budget,
       COUNT(ep.emp_id)                                   AS team_size,
       ISNULL(SUM(ep.hours_allocated), 0)                 AS total_weekly_hours,
       p.budget / NULLIF(COUNT(ep.emp_id), 0)             AS budget_per_member,
       MAX(CASE WHEN ep.Role_on_project = 'Project Lead'
                THEN e.first_name + ' ' + e.last_name END) AS project_lead
FROM dbo.projects p
LEFT JOIN dbo.employee_projects ep ON ep.proj_id = p.proj_id
LEFT JOIN dbo.employees e          ON e.emp_id = ep.emp_id
GROUP BY p.proj_id, p.project_name, p.status,
         p.start_date, p.end_date, p.budget;
GO


/* ----------------------------------------------------------
   vw_employee_workload
   Weekly hours per employee, with a simple capacity flag.
   Includes employees with no projects (0 hours).
   ---------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_employee_workload
AS
SELECT e.emp_id,
       e.first_name + ' ' + e.last_name       AS employee_name,
       d.dept_name,
       COUNT(ep.proj_id)                      AS project_count,
       ISNULL(SUM(ep.hours_allocated), 0)     AS total_weekly_hours,
       CASE
           WHEN ISNULL(SUM(ep.hours_allocated), 0) > 40  THEN 'Overallocated'
           WHEN ISNULL(SUM(ep.hours_allocated), 0) >= 30 THEN 'At capacity'
           ELSE 'Has capacity'
       END                                    AS workload_status
FROM dbo.employees e
JOIN dbo.departments d             ON d.dept_id = e.dept_id
LEFT JOIN dbo.employee_projects ep ON ep.emp_id = e.emp_id
GROUP BY e.emp_id, e.first_name, e.last_name, d.dept_name;
GO


/* ==========================================================
   STORED PROCEDURES
   ========================================================== */

/* ----------------------------------------------------------
   usp_get_department_report
   Returns two result sets for a department:
     1. its employees, highest paid first
     2. the projects its employees work on, with hours
   Usage: EXEC dbo.usp_get_department_report @dept_name = 'IT';
   ---------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_get_department_report
    @dept_name VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dept_id INT =
        (SELECT dept_id FROM dbo.departments WHERE dept_name = @dept_name);

    IF @dept_id IS NULL
    BEGIN
        THROW 50001, 'Department not found. Check the spelling of the department name.', 1;
    END;

    -- Result set 1: employees in the department
    SELECT emp_id, employee_name, job_title, salary,
           hire_date, tenure_years, manager_name
    FROM dbo.vw_employee_details
    WHERE dept_name = @dept_name
    ORDER BY salary DESC;

    -- Result set 2: projects the department's employees are assigned to
    SELECT p.proj_id,
           p.project_name,
           p.status,
           COUNT(*)                  AS employees_from_dept,
           SUM(ep.hours_allocated)   AS weekly_hours_from_dept
    FROM dbo.projects p
    JOIN dbo.employee_projects ep ON ep.proj_id = p.proj_id
    JOIN dbo.employees e          ON e.emp_id = ep.emp_id
    WHERE e.dept_id = @dept_id
    GROUP BY p.proj_id, p.project_name, p.status
    ORDER BY weekly_hours_from_dept DESC;
END;
GO


/* ----------------------------------------------------------
   usp_assign_employee_to_project
   Adds an employee to a project after checking that:
     - the employee and project exist
     - the employee is not already on the project
     - the new hours keep the employee at 40 or fewer per week
   Usage:
     EXEC dbo.usp_assign_employee_to_project
          @emp_id = 5, @proj_id = 21, @role = 'Analyst', @hours = 10;
   ---------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_assign_employee_to_project
    @emp_id  INT,
    @proj_id INT,
    @role    VARCHAR(50),
    @hours   INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE emp_id = @emp_id)
            THROW 50010, 'Employee does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.projects WHERE proj_id = @proj_id)
            THROW 50011, 'Project does not exist.', 1;

        IF EXISTS (SELECT 1 FROM dbo.employee_projects
                   WHERE emp_id = @emp_id AND proj_id = @proj_id)
            THROW 50012, 'Employee is already assigned to this project.', 1;

        DECLARE @current_hours INT =
            (SELECT ISNULL(SUM(hours_allocated), 0)
             FROM dbo.employee_projects
             WHERE emp_id = @emp_id);

        IF @current_hours + @hours > 40
        BEGIN
            DECLARE @msg NVARCHAR(200) =
                CONCAT('Assignment would exceed 40 weekly hours. Employee already has ',
                       @current_hours, ' hours allocated.');
            THROW 50013, @msg, 1;
        END;

        INSERT INTO dbo.employee_projects (emp_id, proj_id, Role_on_project, hours_allocated)
        VALUES (@emp_id, @proj_id, @role, @hours);

        SELECT 'Assignment added' AS result,
               @emp_id            AS emp_id,
               @proj_id           AS proj_id,
               @current_hours + @hours AS new_total_weekly_hours;
    END TRY
    BEGIN CATCH
        THROW;  -- pass the original error back to the caller
    END CATCH;
END;
GO


/* ==========================================================
   EXAMPLE USAGE
   ========================================================== */

-- Views
SELECT * FROM dbo.vw_employee_details   ORDER BY emp_id;
SELECT * FROM dbo.vw_project_staffing   ORDER BY proj_id;
SELECT * FROM dbo.vw_employee_workload  WHERE workload_status = 'Overallocated';

-- Department report
EXEC dbo.usp_get_department_report @dept_name = 'IT';

-- Assign an employee. The transaction is rolled back so the demo
-- does not change the data. Remove BEGIN TRAN / ROLLBACK to keep it.
BEGIN TRAN;
    EXEC dbo.usp_assign_employee_to_project
         @emp_id = 5, @proj_id = 35, @role = 'Analyst', @hours = 5;
ROLLBACK TRAN;
GO