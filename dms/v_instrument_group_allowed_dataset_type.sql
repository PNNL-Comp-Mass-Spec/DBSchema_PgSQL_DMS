--
-- Name: v_instrument_group_allowed_dataset_type; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_group_allowed_dataset_type AS
 SELECT gt.dataset_type,
    gt.dataset_usage_count AS dataset_count,
    gt.dataset_usage_last_year AS dataset_count_last_year,
    dtn.description AS type_description,
    gt.comment AS usage_for_this_group,
    gt.instrument_group
   FROM (public.t_instrument_group_allowed_ds_type gt
     JOIN public.t_dataset_type_name dtn ON ((gt.dataset_type OPERATOR(public.=) dtn.dataset_type)));


ALTER TABLE public.v_instrument_group_allowed_dataset_type OWNER TO d3l243;

--
-- Name: TABLE v_instrument_group_allowed_dataset_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_group_allowed_dataset_type TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_group_allowed_dataset_type TO writeaccess;

