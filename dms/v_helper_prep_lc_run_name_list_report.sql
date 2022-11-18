--
-- Name: v_helper_prep_lc_run_tab_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_run_tab_list_report AS
 SELECT rankq.tab AS val
   FROM ( SELECT sourceq.tab,
            sourceq.usagecount,
            row_number() OVER (ORDER BY sourceq.usagecount DESC, sourceq.tab) AS usagerank
           FROM ( SELECT t_prep_lc_run.tab,
                    count(*) AS usagecount
                   FROM public.t_prep_lc_run
                  WHERE (NOT (t_prep_lc_run.tab IS NULL))
                  GROUP BY t_prep_lc_run.tab) sourceq) rankq
  ORDER BY rankq.usagerank;


ALTER TABLE public.v_helper_prep_lc_run_tab_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_run_tab_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_run_tab_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_prep_lc_run_tab_list_report TO writeaccess;

