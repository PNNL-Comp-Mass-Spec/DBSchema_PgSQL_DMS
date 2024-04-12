--
-- Name: v_analysis_tool_allowed_instrument_class; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_allowed_instrument_class AS
 SELECT aic.analysis_tool_id,
    aic.instrument_class,
    aic.comment,
    analysistool.analysis_tool AS tool_name,
    analysistool.tool_base_name,
    analysistool.result_type,
    analysistool.active AS tool_active
   FROM (public.t_analysis_tool_allowed_instrument_class aic
     JOIN public.t_analysis_tool analysistool ON ((aic.analysis_tool_id = analysistool.analysis_tool_id)));


ALTER VIEW public.v_analysis_tool_allowed_instrument_class OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_allowed_instrument_class; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_allowed_instrument_class TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_tool_allowed_instrument_class TO writeaccess;

