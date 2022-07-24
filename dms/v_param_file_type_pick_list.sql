--
-- Name: v_param_file_type_pick_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_type_pick_list AS
 SELECT pft.param_file_type_id,
    pft.param_file_type,
        CASE
            WHEN ((pft.param_file_type OPERATOR(public.=) tool.analysis_tool) OR (tool.analysis_tool OPERATOR(public.=) ANY (ARRAY['(none)'::public.citext, 'MASIC_Finnigan'::public.citext, 'SMAQC_MSMS'::public.citext]))) THEN (pft.param_file_type)::text
            ELSE ((((pft.param_file_type)::text || ' ('::text) || (tool.analysis_tool)::text) || ')'::text)
        END AS param_file_type_ex
   FROM (public.t_param_file_types pft
     JOIN public.t_analysis_tool tool ON ((pft.primary_tool_id = tool.analysis_tool_id)))
  WHERE (pft.param_file_type_id > 1);


ALTER TABLE public.v_param_file_type_pick_list OWNER TO d3l243;

--
-- Name: TABLE v_param_file_type_pick_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_type_pick_list TO readaccess;

