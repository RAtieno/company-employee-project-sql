/* 01_create_tables.sql
   Creates the MyDatabase schema: tables, keys, and constraints.
   Run this first, then 02_insert_data.sql. */

IF DB_ID('MyDatabase') IS NULL
    CREATE DATABASE MyDatabase;
GO

USE MyDatabase;
GO

/****** Object:  Table [dbo].[departments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[departments](
	[dept_id] [int] IDENTITY(1,1) NOT NULL,
	[dept_name] [varchar](50) NOT NULL,
 CONSTRAINT [PK_department] PRIMARY KEY CLUSTERED 
(
	[dept_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employee_projects]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employee_projects](
	[emp_id] [int] NOT NULL,
	[proj_id] [int] NOT NULL,
	[Role_on_project] [varchar](50) NULL,
	[hours_allocated] [int] NULL,
 CONSTRAINT [PK_employeeProjects] PRIMARY KEY CLUSTERED 
(
	[emp_id] ASC,
	[proj_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employees]    ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employees](
	[emp_id] [int] IDENTITY(1,1) NOT NULL,
	[first_name] [varchar](50) NOT NULL,
	[last_name] [varchar](50) NOT NULL,
	[email] [varchar](255) NOT NULL,
	[phone] [varchar](25) NULL,
	[salary] [int] NULL,
	[dept_id] [int] NOT NULL,
	[manager_id] [int] NOT NULL,
	[hire_date] [date] NULL,
	[job_title] [varchar](150) NULL,
 CONSTRAINT [PK_employees] PRIMARY KEY CLUSTERED 
(
	[emp_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_employees_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[managers]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[managers](
	[manager_id] [int] IDENTITY(1,1) NOT NULL,
	[first_name] [varchar](50) NOT NULL,
	[last_name] [varchar](50) NOT NULL,
	[email] [varchar](255) NOT NULL,
	[phone] [varchar](25) NULL,
	[dept_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[manager_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[projects]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[projects](
	[proj_id] [int] IDENTITY(1,1) NOT NULL,
	[project_name] [varchar](255) NOT NULL,
	[start_date] [date] NULL,
	[end_date] [date] NULL,
	[budget] [int] NULL,
	[status] [varchar](25) NULL,
 CONSTRAINT [PK__project__3213E83F9790CA10] PRIMARY KEY CLUSTERED 
(
	[proj_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_employees]    Script Date: 11/4/2026 11:15:46 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_employees] ON [dbo].[employees]
(
	[emp_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[employee_projects]  WITH CHECK ADD  CONSTRAINT [FK_ep_employees] FOREIGN KEY([emp_id])
REFERENCES [dbo].[employees] ([emp_id])
GO
ALTER TABLE [dbo].[employee_projects] CHECK CONSTRAINT [FK_ep_employees]
GO
ALTER TABLE [dbo].[employee_projects]  WITH CHECK ADD  CONSTRAINT [FK_ep_projects] FOREIGN KEY([proj_id])
REFERENCES [dbo].[projects] ([proj_id])
GO
ALTER TABLE [dbo].[employee_projects] CHECK CONSTRAINT [FK_ep_projects]
GO
ALTER TABLE [dbo].[employees]  WITH CHECK ADD  CONSTRAINT [FK_employees_department] FOREIGN KEY([dept_id])
REFERENCES [dbo].[departments] ([dept_id])
GO
ALTER TABLE [dbo].[employees] CHECK CONSTRAINT [FK_employees_department]
GO
ALTER TABLE [dbo].[employees]  WITH CHECK ADD  CONSTRAINT [FK_employees_managers] FOREIGN KEY([manager_id])
REFERENCES [dbo].[managers] ([manager_id])
GO
ALTER TABLE [dbo].[employees] CHECK CONSTRAINT [FK_employees_managers]
GO
ALTER TABLE [dbo].[managers]  WITH CHECK ADD FOREIGN KEY([dept_id])
REFERENCES [dbo].[departments] ([dept_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[employee_projects]  WITH CHECK ADD  CONSTRAINT [CK_ep_hours] CHECK  (([hours_allocated]>=(1) AND [hours_allocated]<=(40)))
GO
ALTER TABLE [dbo].[employee_projects] CHECK CONSTRAINT [CK_ep_hours]
GO
ALTER TABLE [dbo].[employees]  WITH CHECK ADD  CONSTRAINT [CK_emp_hire_date] CHECK  (([hire_date]<='2026-12-31'))
GO
ALTER TABLE [dbo].[employees] CHECK CONSTRAINT [CK_emp_hire_date]
GO
ALTER TABLE [dbo].[employees]  WITH CHECK ADD  CONSTRAINT [CK_employees_salary] CHECK  (([salary]>(0)))
GO
ALTER TABLE [dbo].[employees] CHECK CONSTRAINT [CK_employees_salary]
GO
ALTER TABLE [dbo].[projects]  WITH CHECK ADD  CONSTRAINT [CK_project_dates] CHECK  (([end_date]>=[start_date]))
GO
ALTER TABLE [dbo].[projects] CHECK CONSTRAINT [CK_project_dates]
GO
ALTER TABLE [dbo].[projects]  WITH CHECK ADD  CONSTRAINT [CK_project_status] CHECK  (([status]='On Hold' OR [status]='Completed' OR [status]='In Progress' OR [status]='Planned'))
GO
ALTER TABLE [dbo].[projects] CHECK CONSTRAINT [CK_project_status]
GO
