--
-- Name: v_sample_label_reporter_ions_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_label_reporter_ions_list_report AS
 SELECT t_sample_labelling_reporter_ions.label,
    t_sample_labelling_reporter_ions.channel,
    t_sample_labelling_reporter_ions.tag_name,
    t_sample_labelling_reporter_ions.masic_name,
    t_sample_labelling_reporter_ions.reporter_ion_mz
   FROM public.t_sample_labelling_reporter_ions;


ALTER VIEW public.v_sample_label_reporter_ions_list_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_label_reporter_ions_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_label_reporter_ions_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_label_reporter_ions_list_report TO writeaccess;

