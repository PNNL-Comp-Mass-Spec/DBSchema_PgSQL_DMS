--
-- Name: v_instrument_group_dataset_types_active; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_group_dataset_types_active AS
 SELECT instgroup.instrument_group,
    typename.dataset_type AS default_dataset_type,
    public.get_instrument_group_dataset_type_list((instgroup.instrument_group)::text, ','::text) AS allowed_dataset_types
   FROM (public.t_instrument_group instgroup
     JOIN public.t_dataset_type_name typename ON ((instgroup.default_dataset_type = typename.dataset_type_id)))
  WHERE ((instgroup.active = 1) AND (instgroup.requested_run_visible = 1));


ALTER TABLE public.v_instrument_group_dataset_types_active OWNER TO d3l243;

--
-- Name: TABLE v_instrument_group_dataset_types_active; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_group_dataset_types_active TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_group_dataset_types_active TO writeaccess;

