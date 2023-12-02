--
-- Name: v_material_log_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_log_list_report AS
 SELECT ml.entry_id AS id,
    ml.date,
    ml.type_name_cached AS type,
    ml.item,
    ml.initial_state AS initial,
    ml.final_state AS final,
    u.name_with_username AS "user",
    ml.comment,
    tmc.comment AS container_comment,
    ml.item_type
   FROM ((public.t_material_log ml
     LEFT JOIN public.t_users u ON ((ml.username OPERATOR(public.=) u.username)))
     LEFT JOIN public.t_material_containers tmc ON ((ml.item OPERATOR(public.=) tmc.container)));


ALTER VIEW public.v_material_log_list_report OWNER TO d3l243;

--
-- Name: TABLE v_material_log_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_log_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_log_list_report TO writeaccess;

