--
-- Name: v_prep_lc_column_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_column_entry AS
 SELECT prepcolumn.prep_column AS column_name,
    prepcolumn.mfg_name,
    prepcolumn.mfg_model,
    prepcolumn.mfg_serial AS mfg_serial_number,
    prepcolumn.packing_mfg,
    prepcolumn.packing_type,
    prepcolumn.particle_size,
    prepcolumn.particle_type,
    prepcolumn.column_inner_dia,
    prepcolumn.column_outer_dia,
    prepcolumn.length,
    prepcolumn.state,
    prepcolumn.operator_prn,
    prepcolumn.comment,
    prepcolumn.created,
    prepcolumn.prep_column_id AS id
   FROM public.t_prep_lc_column prepcolumn;


ALTER TABLE public.v_prep_lc_column_entry OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_column_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_column_entry TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_column_entry TO writeaccess;

