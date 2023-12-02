--
-- Name: v_instrument_group_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_group_entry AS
 SELECT i.instrument_group,
    i.usage,
    i.comment,
    i.active,
    i.sample_prep_visible,
    i.requested_run_visible,
    i.allocation_tag,
    COALESCE(dt.dataset_type, ''::public.citext) AS default_dataset_type_name
   FROM (public.t_instrument_group i
     LEFT JOIN public.t_dataset_type_name dt ON ((i.default_dataset_type = dt.dataset_type_id)));


ALTER VIEW public.v_instrument_group_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_group_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_group_entry TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_group_entry TO writeaccess;

