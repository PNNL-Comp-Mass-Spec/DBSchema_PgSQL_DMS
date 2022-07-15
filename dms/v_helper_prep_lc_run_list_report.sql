--
-- Name: v_helper_prep_lc_run_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_run_list_report AS
 SELECT t_prep_lc_run.prep_run_id AS id,
    t_prep_lc_run.tab,
    t_prep_lc_run.instrument,
    t_prep_lc_run.type,
    t_prep_lc_run.lc_column,
    t_prep_lc_run.comment,
    t_prep_lc_run.created,
    t_prep_lc_run.number_of_runs
   FROM public.t_prep_lc_run;


ALTER TABLE public.v_helper_prep_lc_run_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_run_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_run_list_report TO readaccess;

