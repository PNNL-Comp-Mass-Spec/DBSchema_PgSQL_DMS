--
-- Name: v_mgr_work_dir; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_work_dir AS
 SELECT mgr_name,
        CASE
            WHEN (value OPERATOR(public.~~) '\\%'::public.citext) THEN value
            ELSE ((('\\ServerName\'::public.citext)::text || public.replace(value, ':\'::public.citext, '$\'::public.citext)))::public.citext
        END AS work_dir_admin_share
   FROM mc.v_param_value
  WHERE (param_name OPERATOR(public.=) 'workdir'::public.citext);


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

