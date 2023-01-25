--
-- Name: v_pipeline_script_parameters; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_parameters AS
 SELECT t_scripts.script_id AS id,
    t_scripts.script,
    t_scripts.parameters,
    t_scripts.fields
   FROM sw.t_scripts;


ALTER TABLE sw.v_pipeline_script_parameters OWNER TO d3l243;

--
-- Name: VIEW v_pipeline_script_parameters; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_pipeline_script_parameters IS 'This view is used by https://dms2.pnl.gov/pipeline_jobs/create
When the user clicks a script name, the code references this view using a URL similar to:
  https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/PRIDE_Converter or
  https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MSFragger_DataPkg
The SQL Server version of this view converts the XML columns parameters and fields to varchar(max) due to a bug in the SQLSRV driver used by CodeIgniter on the the DMS website';

--
-- Name: TABLE v_pipeline_script_parameters; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_parameters TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_parameters TO writeaccess;

