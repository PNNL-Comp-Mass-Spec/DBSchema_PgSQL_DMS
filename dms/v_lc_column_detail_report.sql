--
-- Name: v_lc_column_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_column_detail_report AS
 SELECT lc.lc_column AS column_name,
    statename.column_state AS state,
    lc.created,
    lc.packing_mfg,
    lc.packing_type,
    lc.particle_size,
    lc.particle_type,
    lc.column_inner_dia AS "I.D.",
    lc.column_outer_dia AS "O.D.",
    lc.column_length AS length,
    lc.operator_prn AS operator,
    lc.comment,
    lc.lc_column_id AS column_id
   FROM (public.t_lc_column lc
     JOIN public.t_lc_column_state_name statename ON ((lc.column_state_id = statename.column_state_id)));


ALTER TABLE public.v_lc_column_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_column_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_column_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_column_detail_report TO writeaccess;

