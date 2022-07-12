--
-- Name: v_entity_rename_log; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_entity_rename_log AS
 SELECT erl.entry_id,
    erl.target_type,
    et.target_type AS type_name,
    erl.target_id,
    erl.old_name,
    erl.new_name,
    erl.entered,
    erl.entered_by,
    et.target_table,
    et.target_id_column
   FROM (public.t_entity_rename_log erl
     JOIN public.t_event_target et ON ((erl.target_type = et.target_type_id)));


ALTER TABLE public.v_entity_rename_log OWNER TO d3l243;

--
-- Name: TABLE v_entity_rename_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_entity_rename_log TO readaccess;

