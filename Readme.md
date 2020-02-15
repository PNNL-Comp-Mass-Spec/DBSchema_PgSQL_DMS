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
[PMID: 16470653](https://www.ncbi.nlm.nih.gov/pubmed/?term=16470653)

# Details

The original database schema for DMS is in the Microsoft SQL Server format, and can be found 
in the [DBSchema_DMS repo](https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS) on GitHub.

Migration of the SQL Server tables, views, stored procedures and functions is in progress.  
The following table describes the PostgreSQL schemas for DMS, along with the Source SQL Server Database for each schema.

# Schema 

|Database | Schema   | Description                         | Source SQL Server DB   |
|---------|----------|-------------------------------------|------------------------|
| dms     | public   | Main DMS tables                     | DMS5                   |
| dms     | cap      | Dataset capture and archive tasks   | DMS_Capture            |
| dms     | sw       | Software analysis jobs              | DMS_Pipeline           |
| dms     | mc       | Manager parameters                  | Manager_Control        |
| dms     | ont      | Ontology tables                     | Ontology_Lookup        |
| dms     | dpkg     | Data packages                       | DMS_Data_Package       |
| pc      | public   | Protein Collections (FASTA files)   | Protein_Sequences      |
| hlog    | public   | Historic logs                       | DMSHistoricLog         |
| hlog    | cap      | Historic logs                       | DMSHistoricLogCapture  |
| hlog    | sw       | Historic logs                       | DMSHistoricLogPipeline |
| mts     | public   | MTS metadata DBs                    | MTS_Master             |
| mts     | mtmain   | MTS metadata DBs                    | MT_Main                |
| mts     | prismifc | MTS metadata DBs                    | Prism_IFC              |


# License

Licensed under the Apache License, Version 2.0; you may not use this file except 
in compliance with the License.  You may obtain a copy of the License at 
http://www.apache.org/licenses/LICENSE-2.0
