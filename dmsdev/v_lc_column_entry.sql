--
-- Name: v_lc_column_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_column_entry AS
 SELECT lc.lc_column,
    lc.packing_mfg,
    lc.packing_type,
    lc.particle_size,
    lc.particle_type,
    lc.column_inner_dia,
    lc.column_outer_dia,
    lc.column_length,
    lc.operator_username,
    lc.comment,
    lc.lc_column_id AS column_id,
    statename.column_state
   FROM (public.t_lc_column lc
     JOIN public.t_lc_column_state_name statename ON ((lc.column_state_id = statename.column_state_id)));


ALTER VIEW public.v_lc_column_entry OWNER TO d3l243;

--
-- Name: TABLE v_lc_column_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_column_entry TO readaccess;
GRANT SELECT ON TABLE public.v_lc_column_entry TO writeaccess;

