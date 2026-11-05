Bash Automation – Procurement Process Intelligence Hub
1. Overview
This project includes a lightweight Bash automation layer designed to validate processed procurement data and verify PostgreSQL database integrity.

The objective is to demonstrate practical Bash scripting skills within a real-world data analytics project without introducing unnecessary complexity.

The automation consists of:
- 2 Bash scripts
- 1 SQL validation file
The pipeline validates existing project outputs. It does not rerun the ETL process or reload data into PostgreSQL.
2. Project Structure
project/
├── scripts/
│   ├── validate_project.sh
│   ├── run_pipeline.sh
│   └── backup_postgres.sh
├── sql/
│   └── validate_database.sql
├── data/
│   ├── processed/
│   └── quality/
└── logs/


Note: backup_postgres.sh exists in the project but was not used or validated in this automation workflow.
3. Environment Setup
The project was tested on macOS with PostgreSQL 18.

Add PostgreSQL command-line tools to the current Terminal session:
export PATH="/Library/PostgreSQL/18/bin:$PATH"


Set the PostgreSQL username:
export PGUSER=postgres


The database password is entered when PostgreSQL prompts for it. Passwords should never be hardcoded into scripts or committed to GitHub.
4. Script 1 – validate_project.sh
Purpose: Validate the availability of the project's processed data files and required tools.

Run basic project validation:
./scripts/validate_project.sh


Run validation including PostgreSQL:
./scripts/validate_project.sh --with-db


The script performs the following checks:
- Verifies the existence of the three processed Parquet files.
- Verifies the existence of etl_validation.csv.
- Checks Python availability.
- Checks PostgreSQL table row counts when --with-db is supplied.
- Records execution results in a log file.
- Reports success or failure.
Test result: Successfully executed.

The PostgreSQL check initially attempted to use the macOS account name (hassan). Setting PGUSER=postgres resolved the authentication issue without modifying the script.
5. SQL Validation – validate_database.sql
Purpose: Validate PostgreSQL table row counts and basic data integrity against the documented BPI Challenge 2019 project extract and date filter.

Execute the SQL file directly from Bash:
psql -h localhost -p 5432 \
  -U "$PGUSER" \
  -d procurement_intelligence \
  -v ON_ERROR_STOP=1 \
  -f sql/validate_database.sql


The SQL validation checks:
Validation	Expected Result
dim_procurement_case rows	251,463
fact_procurement_event rows	1,587,802
mart_invoice_monitoring rows	211,113
Distinct event cases	251,463
Events with missing case, activity, or timestamp	0

The SQL script uses a PostgreSQL DO block with conditional checks and raises exceptions when validation conditions fail.

The ON_ERROR_STOP=1 option ensures that psql stops execution when an SQL error occurs.
All 5 checks passed
6. Script 2 – run_pipeline.sh
Purpose: Orchestrate project validation and database validation through a single Bash command.

Make the script executable:
chmod +x scripts/run_pipeline.sh


Execute the pipeline:
./scripts/run_pipeline.sh


The script performs the following operations:
1. Moves to the project root directory.
2. Creates the logs directory if it does not exist.
3. Generates a timestamped log filename.
4. Executes validate_project.sh --with-db.
5. Executes validate_database.sql through PostgreSQL.
6. Stops execution if a command fails.
7. Saves execution output to a log file.
8. Prints a success message after successful completion.
The script demonstrates several Bash concepts:
- Variables.
- Environment variables.
- Command substitution.
- Directory management.
- Command sequencing.
- Error handling with set -e.
- Pipes and output redirection using tee.
- External command execution.
Exit Code Verification
After running the pipeline:
./scripts/run_pipeline.sh
echo $?


Expected result:
0


An exit code of 0 indicates successful execution.
Pipeline execution successful
7. Automation Workflow
             run_pipeline.sh
                    |
                    v
       validate_project.sh --with-db
                    |
                    v
       Validate processed data files
                    |
                    v
       Check PostgreSQL connectivity
                    |
                    v
        validate_database.sql
                    |
                    v
       Validate database integrity
                    |
                    v
          Generate execution log
                    |
                    v
           Pipeline completed


8. Final Validation Results
The successful execution confirmed the following database metrics:
Metric	Result
Procurement cases	251,463
Procurement events	1,587,802
Invoice monitoring records	211,113
Distinct event cases	251,463
Missing event keys	0

The pipeline completed successfully with exit code 0.
9. Scope and Limitations
This implementation represents a Bash validation and orchestration workflow.

It does not:
- Rebuild the Parquet files.
- Rerun the Jupyter notebook or ETL transformations.
- Reload records into PostgreSQL.
- Schedule automatic or recurring execution.
The processed data files and PostgreSQL tables already existed when this automation workflow was tested.

The existing backup_postgres.sh script was not included in the tested workflow.
10. Bash Skills Demonstrated
Bash Skill	Project Application
Variables	Project paths and log filenames
Environment Variables	PGUSER and PATH
Command-line Arguments	--with-db
Exit Codes	Checking execution success or failure
Error Handling	set -e and SQL error handling
Pipes and Redirection	2>&1 \| tee
Command Substitution	Generating timestamps using date
File Operations	Checking project files
Directory Management	Creating the logs directory
External Command Execution	Running PostgreSQL commands
Logging	Recording pipeline execution output

Conclusion

This implementation demonstrates how Bash can coordinate validation tasks across project files and PostgreSQL, providing a simple and reproducible automation workflow for a procurement analytics project.