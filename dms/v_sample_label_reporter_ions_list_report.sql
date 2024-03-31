--
-- Name: v_sample_label_reporter_ions_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_label_reporter_ions_list_report AS
 SELECT label,
    channel,
    tag_name,
    masic_name,
    reporter_ion_mz
   FROM public.t_sample_labelling_reporter_ions;


ALTER VIEW public.v_sample_label_reporter_ions_list_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_label_reporter_ions_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_label_reporter_ions_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_label_reporter_ions_list_report TO writeaccess;

