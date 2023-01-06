--
-- Name: v_lcmsnet_column_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lcmsnet_column_export AS
 SELECT lc.lc_column AS column_number,
    lc.column_state_id AS state_id,
    statename.column_state AS state,
    lc.created,
    lc.operator_prn AS operator,
    lc.comment,
    lc.lc_column_id AS id
   FROM (public.t_lc_column lc
     JOIN public.t_lc_column_state_name statename ON ((lc.column_state_id = statename.column_state_id)));


ALTER TABLE public.v_lcmsnet_column_export OWNER TO d3l243;

--
-- Name: VIEW v_lcmsnet_column_export; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_lcmsnet_column_export IS 'Used by method GetColumnListFromDMS() in Buzzard\BuzzardWPF\IO\DMS\DMSDBTools.cs';

--
-- Name: TABLE v_lcmsnet_column_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lcmsnet_column_export TO readaccess;
GRANT SELECT ON TABLE public.v_lcmsnet_column_export TO writeaccess;

