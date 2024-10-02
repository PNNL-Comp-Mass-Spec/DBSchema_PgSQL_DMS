--
-- Name: v_pipeline_scripts; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_scripts AS
 SELECT script_id AS id,
    script,
    description,
    enabled,
    results_tag,
    backfill_to_dms,
    (contents)::public.citext AS contents,
    (parameters)::public.citext AS parameters,
    (fields)::public.citext AS fields
   FROM sw.t_scripts;


ALTER VIEW sw.v_pipeline_scripts OWNER TO d3l243;

--
-- Name: VIEW v_pipeline_scripts; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_pipeline_scripts IS 'This view is used by https://dms2.pnl.gov/pipeline_jobs/create. When the user clicks a script name, the code references this view using a URL similar to these:
  https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/PRIDE_Converter
  https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MAC_iTRAQ
  https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/FragPipe_DataPkg
  https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MSFragger_DataPkg
  https://dms2.pnl.gov/pipeline_script/dot/MSGFPlus (linked to from https://dms2.pnl.gov/pipeline_script/show/MSGFPlus using "Script")

This view casts the XML to text to workaround a bug in the SQLSRV driver used by CodeIgniter on the the DMS website';

--
-- Name: TABLE v_pipeline_scripts; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_scripts TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_scripts TO writeaccess;

