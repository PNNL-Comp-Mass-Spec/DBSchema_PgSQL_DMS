--
-- Name: v_mgr_work_dir; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_work_dir AS
 SELECT v_param_value.m_name,
        CASE
            WHEN (v_param_value.value OPERATOR(public.~~) '\\%'::public.citext) THEN (v_param_value.value)::text
            ELSE ('\\ServerName\'::text || public.replace(v_param_value.value, ':\'::public.citext, '$\'::public.citext))
        END AS workdir_adminshare
   FROM mc.v_param_value
  WHERE (v_param_value.param_name OPERATOR(public.=) 'workdir'::public.citext);


ALTER TABLE mc.v_mgr_work_dir OWNER TO d3l243;

--
-- Name: TABLE v_mgr_work_dir; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_work_dir TO readaccess;
