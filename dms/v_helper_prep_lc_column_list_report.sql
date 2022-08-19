--
-- Name: v_helper_prep_lc_column_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_column_list_report AS
 SELECT t_prep_lc_column.prep_column AS column_name,
    t_prep_lc_column.mfg_name,
    t_prep_lc_column.mfg_model,
    t_prep_lc_column.mfg_serial AS mfg_serial_number,
    t_prep_lc_column.comment,
    t_prep_lc_column.created
   FROM public.t_prep_lc_column
  WHERE (t_prep_lc_column.state OPERATOR(public.=) 'Active'::public.citext);


ALTER TABLE public.v_helper_prep_lc_column_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_column_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_column_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_prep_lc_column_list_report TO writeaccess;

