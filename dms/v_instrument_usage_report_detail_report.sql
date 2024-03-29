--
-- Name: v_instrument_usage_report_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_usage_report_detail_report AS
 SELECT instusage.emsl_inst_id,
    instname.instrument,
    instusage.type,
    instusage.start,
    instusage.minutes,
    instusage.proposal,
    instusagetype.usage_type AS usage,
    instusage.users,
    instusage.operator,
    instusage.comment,
    instusage.year,
    instusage.month,
    instusage.dataset_id,
    instusage.seq
   FROM ((public.t_emsl_instrument_usage_report instusage
     JOIN public.t_instrument_name instname ON ((instusage.dms_inst_id = instname.instrument_id)))
     LEFT JOIN public.t_emsl_instrument_usage_type instusagetype ON ((instusage.usage_type_id = instusagetype.usage_type_id)));


ALTER VIEW public.v_instrument_usage_report_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_usage_report_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_usage_report_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_usage_report_detail_report TO writeaccess;

