--
-- Name: v_helper_prep_lc_run_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_run_list_report AS
 SELECT prep_run_id AS id,
    prep_run_name,
    instrument,
    type,
    lc_column,
    comment,
    created,
    number_of_runs
   FROM public.t_prep_lc_run;


ALTER VIEW public.v_helper_prep_lc_run_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_run_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_run_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_prep_lc_run_list_report TO writeaccess;

