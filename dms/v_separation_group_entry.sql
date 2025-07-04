--
-- Name: v_separation_group_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_separation_group_entry AS
 SELECT separation_group,
    comment,
    active,
    sample_prep_visible,
    fraction_count,
    acq_length_minutes
   FROM public.t_separation_group sg;


ALTER VIEW public.v_separation_group_entry OWNER TO d3l243;

--
-- Name: TABLE v_separation_group_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_separation_group_entry TO readaccess;
GRANT SELECT ON TABLE public.v_separation_group_entry TO writeaccess;

