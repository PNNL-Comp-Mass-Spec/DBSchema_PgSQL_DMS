--
-- Name: v_mgr_work_dir; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_work_dir AS
 SELECT v_param_value.mgr_name,
        CASE
            WHEN (v_param_value.value OPERATOR(public.~~) '\\%'::public.citext) THEN v_param_value.value
            ELSE ((('\\ServerName\'::public.citext)::text || public.replace(v_param_value.value, ':\'::public.citext, '$\'::public.citext)))::public.citext
        END AS work_dir_admin_share
   FROM mc.v_param_value
  WHERE (v_param_value.param_name OPERATOR(public.=) 'workdir'::public.citext);


ALTER VIEW mc.v_mgr_work_dir OWNER TO d3l243;

--
-- Name: VIEW v_mgr_work_dir; Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON VIEW mc.v_mgr_work_dir IS 'This database does not keep track of the server name that a given manager is running on. Thus, this query includes the generic text ServerName for the WorkDir path, unless the WorkDir is itself a network share';

--
-- Name: TABLE v_mgr_work_dir; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_work_dir TO readaccess;
GRANT SELECT ON TABLE mc.v_mgr_work_dir TO writeaccess;

