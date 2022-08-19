--
-- Name: v_instrument_group_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_group_list_report AS
 SELECT g.instrument_group,
    g.usage,
    g.comment,
    g.active,
    g.sample_prep_visible,
    g.requested_run_visible,
    g.allocation_tag,
    COALESCE(dt.dataset_type, ''::public.citext) AS default_dataset_type,
    public.get_instrument_group_membership_list(g.instrument_group, 0, 0) AS instruments,
    public.get_instrument_group_dataset_type_list((g.instrument_group)::text, ', '::text) AS allowed_dataset_types
   FROM (public.t_instrument_group g
     LEFT JOIN public.t_dataset_type_name dt ON ((g.default_dataset_type = dt.dataset_type_id)));


ALTER TABLE public.v_instrument_group_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_group_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_group_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_group_list_report TO writeaccess;

