--
-- Name: v_prep_lc_column_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_column_detail_report AS
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
    prepcolumn.operator_username,
    prepcolumn.comment,
    prepcolumn.created,
    prepcolumn.prep_column_id AS id,
    sum(t_prep_lc_run.number_of_runs) AS runs
   FROM (public.t_prep_lc_column prepcolumn
     LEFT JOIN public.t_prep_lc_run ON ((prepcolumn.prep_column OPERATOR(public.=) t_prep_lc_run.lc_column)))
  GROUP BY prepcolumn.prep_column, prepcolumn.mfg_name, prepcolumn.mfg_model, prepcolumn.mfg_serial, prepcolumn.packing_mfg, prepcolumn.packing_type, prepcolumn.particle_size, prepcolumn.particle_type, prepcolumn.column_inner_dia, prepcolumn.column_outer_dia, prepcolumn.length, prepcolumn.state, prepcolumn.operator_username, prepcolumn.comment, prepcolumn.created, prepcolumn.prep_column_id;


ALTER TABLE public.v_prep_lc_column_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_column_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_column_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_column_detail_report TO writeaccess;

