--
-- Name: v_helper_prep_lc_run_name_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_run_name_list_report AS
 SELECT prep_run_name AS val
   FROM ( SELECT sourceq.prep_run_name,
            sourceq.usagecount,
            row_number() OVER (ORDER BY sourceq.usagecount DESC, sourceq.prep_run_name) AS usagerank
           FROM ( SELECT t_prep_lc_run.prep_run_name,
                    count(t_prep_lc_run.prep_run_id) AS usagecount
                   FROM public.t_prep_lc_run
                  WHERE (NOT (t_prep_lc_run.prep_run_name IS NULL))
                  GROUP BY t_prep_lc_run.prep_run_name) sourceq) rankq
  ORDER BY usagerank
 LIMIT 1000;


ALTER VIEW public.v_helper_prep_lc_run_name_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_run_name_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_run_name_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_prep_lc_run_name_list_report TO writeaccess;

