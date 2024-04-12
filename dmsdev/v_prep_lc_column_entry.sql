--
-- Name: v_prep_lc_column_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_column_entry AS
 SELECT prep_column AS column_name,
    mfg_name,
    mfg_model,
    mfg_serial AS mfg_serial_number,
    packing_mfg,
    packing_type,
    particle_size,
    particle_type,
    column_inner_dia,
    column_outer_dia,
    length,
    state,
    operator_username,
    comment,
    created,
    prep_column_id AS id
   FROM public.t_prep_lc_column prepcolumn;


ALTER VIEW public.v_prep_lc_column_entry OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_column_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_column_entry TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_column_entry TO writeaccess;

