--
-- Name: v_settings_file_lookup; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_settings_file_lookup AS
 SELECT analysis_tool,
    file_name,
    mapped_tool
   FROM ( SELECT sf.file_name,
            sf.analysis_tool,
            sf.analysis_tool AS mapped_tool
           FROM (public.t_settings_files sf
             JOIN public.t_analysis_tool antool ON ((sf.analysis_tool OPERATOR(public.=) antool.analysis_tool)))
          WHERE (sf.active <> 0)
        UNION
         SELECT sf.file_name,
            antool.analysis_tool,
            sf.analysis_tool AS mapped_tool
           FROM (public.t_settings_files sf
             JOIN public.t_analysis_tool antool ON ((sf.analysis_tool OPERATOR(public.=) antool.tool_base_name)))
          WHERE (sf.active <> 0)) sourceq;


ALTER VIEW public.v_settings_file_lookup OWNER TO d3l243;

--
-- Name: TABLE v_settings_file_lookup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_settings_file_lookup TO readaccess;
GRANT SELECT ON TABLE public.v_settings_file_lookup TO writeaccess;

