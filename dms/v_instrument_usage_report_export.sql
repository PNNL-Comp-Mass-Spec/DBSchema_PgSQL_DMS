--
-- Name: v_instrument_usage_report_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_usage_report_export AS
 SELECT instusage.emsl_inst_id,
    instname.instrument,
    instusage.type,
    instusage.start,
    instusage.minutes,
    instusage.proposal,
    instusagetype.usage_type AS usage,
    instusage.users,
    instusage.operator,
    COALESCE(u.name, eu.name_fm) AS operator_name,
    instusage.comment,
    instusage.year,
    instusage.month,
    instusage.dataset_id,
    instusage.seq,
    instusage.updated,
    instusage.updated_by AS updatedby
   FROM ((((public.t_emsl_instrument_usage_report instusage
     JOIN public.t_instrument_name instname ON ((instusage.dms_inst_id = instname.instrument_id)))
     LEFT JOIN public.t_emsl_instrument_usage_type instusagetype ON ((instusage.usage_type_id = instusagetype.usage_type_id)))
     LEFT JOIN public.t_eus_users eu ON ((instusage.operator = eu.person_id)))
     LEFT JOIN public.t_users u ON ((eu.hid OPERATOR(public.=) u.hid)))
  WHERE (instusage.dataset_id_acq_overlap IS NULL);


ALTER TABLE public.v_instrument_usage_report_export OWNER TO d3l243;

--
-- Name: TABLE v_instrument_usage_report_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_usage_report_export TO readaccess;

