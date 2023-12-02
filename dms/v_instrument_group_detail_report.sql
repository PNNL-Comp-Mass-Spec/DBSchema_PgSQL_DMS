--
-- Name: v_instrument_group_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_group_detail_report AS
 SELECT i.instrument_group,
    i.usage,
    i.comment,
    i.active,
    i.sample_prep_visible,
    i.requested_run_visible,
    i.allocation_tag,
    COALESCE(dt.dataset_type, ''::public.citext) AS default_dataset_type,
    ('!Headers!Instrument Name:Instrument ID|'::text || public.get_instrument_group_membership_list(i.instrument_group, 2, 0)) AS instruments,
    public.get_instrument_group_dataset_type_list((i.instrument_group)::text, ', '::text) AS allowed_dataset_types
   FROM (public.t_instrument_group i
     LEFT JOIN public.t_dataset_type_name dt ON ((i.default_dataset_type = dt.dataset_type_id)));


ALTER VIEW public.v_instrument_group_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_group_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_group_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_group_detail_report TO writeaccess;

