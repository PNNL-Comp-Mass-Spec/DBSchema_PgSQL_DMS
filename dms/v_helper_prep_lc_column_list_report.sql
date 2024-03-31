--
-- Name: v_helper_prep_lc_column_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_column_list_report AS
 SELECT prep_column AS column_name,
    mfg_name,
    mfg_model,
    mfg_serial AS mfg_serial_number,
    comment,
    created
   FROM public.t_prep_lc_column
  WHERE (state OPERATOR(public.=) 'Active'::public.citext);


ALTER VIEW public.v_helper_prep_lc_column_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_column_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_column_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_prep_lc_column_list_report TO writeaccess;

