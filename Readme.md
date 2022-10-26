# Overview

This is a collection of DDL files that define the database schema used by
the Data Management System (DMS) component of the Pan-Omics Research 
Information Storage and Management system (PRISM) at the Pacific Northwest 
National Laboratory (PNNL).  PRISM incorporates a diverse set of analysis 
tools and allows a wide range of operations to be incorporated, leveraging 
a state machine that is accessible to independent, distributed computational 
nodes. The system has scaled well as data volume has increased since 2002, 
while allowing adaptability for incorporating new and improved data analysis 
tools for more effective proteomics research.

## Manuscript

For more information see the manuscript "PRISM: a data management system 
for high-throughput proteomics" published in the journal Proteomics in 2006:
[PMID: 16470653](https://pubmed.ncbi.nlm.nih.gov/16470653/)

# Details

The original database schema for DMS is in the Microsoft SQL Server format, and can be found 
in the [DBSchema_DMS repo](https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS) on GitHub.

Migration of the SQL Server tables, views, stored procedures and functions to PostgreSQL is a work in progress.

## Schema

The following table describes the PostgreSQL schemas for DMS, along with the Source SQL Server Database for each schema.

|Database | Schema   | Description                         | Source SQL Server DB   |
|---------|----------|-------------------------------------|------------------------|
| dms     | public   | Main DMS tables                     | DMS5                   |
| dms     | cap      | Dataset capture and archive tasks   | DMS_Capture            |
| dms     | sw       | Software analysis jobs              | DMS_Pipeline           |
| dms     | mc       | Manager parameters                  | Manager_Control        |
| dms     | ont      | Ontology tables                     | Ontology_Lookup        |
| dms     | dpkg     | Data packages                       | DMS_Data_Package       |
| dms     | pc       | Protein Collections (FASTA files)   | Protein_Sequences      |
| dms     | logdms   | Historic logs                       | DMSHistoricLog         |
| dms     | logcap   | Dataset capture historic logs       | DMSHistoricLogCapture  |
| dms     | logsw    | Software analysis historic logs     | DMSHistoricLogPipeline |
| mts     | public   | MTS metadata DBs                    | MTS_Master             |
| mts     | mtmain   | MTS metadata DBs                    | MT_Main                |
| mts     | prismifc | MTS metadata DBs                    | Prism_IFC              |

## Schema and Data Migration Steps

1. Use SSMS to script out tables, indexes, triggers, relationships, and views from SQL Server

2. Use the DB Schema Export Tool to pre-process the scripted DDL to rename columns and skip unwanted tables and views
* In the [DB-Schema-Export-Tool repo](https://github.com/PNNL-Comp-Mass-Spec/DB-Schema-Export-Tool) on GitHub
* Three input files:
  * Schema DDL file from step 1
    * Defined with the `ExistingDDL=Database.sql` parameter
  * Text file defining the source and target table names, along with primary key columns
    * Also defines tables to skip
    * Defined with the `DataTables=Database_Tables.tsv` parameter in the ExportOptions parameter file
  * Text file defining the source and target column names, optionally defining columns to skip
    * Defined with the `ColumnMap=Database_Table_Columns.tsv` parameter in the ExportOptions parameter file

3. Use the sqlserver2pgsql tool to convert the DDL to PostgreSQL syntax, including citext
* sqlserver2pgsql is a perl script
  * Originally from https://github.com/dalibo/sqlserver2pgsql
  * Now in the [sqlserver2pgsql repo](https://github.com/PNNL-Comp-Mass-Spec/sqlserver2pgsql) on GitHub
* It creates updated DDL files
* It also creates a text file (named Database_ColumnNameMap.txt) listing the old and new table and column names

4. Use the PgSql View Creator Helper program (PgSqlViewCreatorHelper) to update the DDL for views
* See the [PgSQL-View-Creator-Helper repo](https://github.com/PNNL-Comp-Mass-Spec/PgSQL-View-Creator-Helper) on GitHub
* This program also creates a merged ColumnNameMap file (Database_ColumnNameMap_merged.txt) that merges two map files from the previous steps
  * The ColumnNameMap.txt file created by sqlserver2pgsql
  * The ColumnMap file provided to the DB Schema Export Tool, listing source and target column names

5. Create tables and views in the PostgreSQL database
* Tables and views can be manually updated, if necessary

6. Script out the schema for tables, views, etc. in the PostgreSQL database
* Again, use the DB Schema Export Tool, but this time the source database is the PostgreSQL server
* Store the scripted objects in a git repo
  * See the [DBSchema_DMS repo](https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS)

7. Transfer Table Data
* Use the DB Schema Export Tool tool to export data from all of the tables in SQL Server
* Three input files:
  * Text file defining the source and target table names, along with primary key columns; also defines tables to skip
  * Text file defining the source and target column names, optionally defining columns to skip
  * Text file with table names defining the order that data should be exported from tables
    * The export order also dictates the order that tables will be listed in the shell script created for importing data into the target database
* The program will create one file per table, with the data for that table scripted as `INSERT ... ON CONFLICT DO UPDATE` statements
* It also creates a shell script for loading the data for each table
  * Import data to to the PostgreSQL database by running the shell script

8. Append new table data
* New data added to tables in SQL Server can be added to the PostgreSQL database
* Use the DB Schema Export Tool tool, with a parameter file that has TableDataDateFilter defined
  * This points to a tab-delimited text file with columns SourceTableName, DateColumnName, and MinimumDate
* The program will create one file per table
* It also creates a shell script for loading the data for each table
  * Import data to to the PostgreSQL database by running the shell script

9. Convert stored procedures
* Use SQL Server Management Studio (SSMS) to script out stored procedures and user defined functions from a database
* Convert the scripted DDL using the SQLServer Stored Procedure Converter
  * See the [SQLServer-Stored-Procedure-Converter repo](https://github.com/PNNL-Comp-Mass-Spec/SQLServer-Stored-Procedure-Converter) on GitHub
  * Uses the merged ColumnNameMap file created by the PgSqlViewCreatorHelper to rename tables and columns referenced in the stored procedures


# License

Licensed under the Apache License, Version 2.0; you may not use this program except 
in compliance with the License.  You may obtain a copy of the License at 
http://www.apache.org/licenses/LICENSE-2.0
