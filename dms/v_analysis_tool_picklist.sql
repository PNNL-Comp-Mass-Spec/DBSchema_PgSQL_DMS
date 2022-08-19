--
-- Name: v_analysis_tool_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_picklist AS
 SELECT t_analysis_tool.analysis_tool_id AS id,
    t_analysis_tool.analysis_tool AS name
   FROM public.t_analysis_tool
  WHERE (t_analysis_tool.active > 0);


ALTER TABLE public.v_analysis_tool_picklist OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_tool_picklist TO writeaccess;

