--
-- Name: v_instrument_allowed_dataset_type_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_allowed_dataset_type_list_report AS
 SELECT 'Edit'::text AS sel,
    gt.instrument_group,
    gt.dataset_type,
    dtn.description AS type_description,
    gt.comment AS usage_for_this_group
   FROM (public.t_instrument_group_allowed_ds_type gt
     JOIN public.t_dataset_type_name dtn ON ((gt.dataset_type OPERATOR(public.=) dtn.dataset_type)));


ALTER TABLE public.v_instrument_allowed_dataset_type_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_allowed_dataset_type_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_allowed_dataset_type_list_report TO readaccess;

