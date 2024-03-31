--
-- Name: v_mac_job_type_picklist; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_mac_job_type_picklist AS
 SELECT script_id AS id,
    script,
    description
   FROM sw.t_scripts
  WHERE ((script OPERATOR(public.~) similar_to_escape('MAC[_]%'::text)) AND (enabled OPERATOR(public.=) 'Y'::public.citext) AND (NOT (parameters IS NULL)));


ALTER VIEW sw.v_mac_job_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_mac_job_type_picklist; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_mac_job_type_picklist TO readaccess;
GRANT SELECT ON TABLE sw.v_mac_job_type_picklist TO writeaccess;

