--
-- Name: v_sample_prep_request_items_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_items_list_report AS
 SELECT t_sample_prep_request_items.prep_request_id AS id,
    t_sample_prep_request_items.item_id,
    t_sample_prep_request_items.item_name,
    t_sample_prep_request_items.item_type,
    t_sample_prep_request_items.status,
    t_sample_prep_request_items.created,
    t_sample_prep_request_items.item_added,
        CASE
            WHEN (t_sample_prep_request_items.item_type OPERATOR(public.=) 'dataset'::public.citext) THEN (t_sample_prep_request_items.item_name)::text
            WHEN (t_sample_prep_request_items.item_type OPERATOR(public.=) 'experiment'::public.citext) THEN (t_sample_prep_request_items.item_name)::text
            WHEN (t_sample_prep_request_items.item_type OPERATOR(public.=) 'experiment_group'::public.citext) THEN (t_sample_prep_request_items.item_id)::text
            WHEN (t_sample_prep_request_items.item_type OPERATOR(public.=) 'material_container'::public.citext) THEN (t_sample_prep_request_items.item_name)::text
            WHEN (t_sample_prep_request_items.item_type OPERATOR(public.=) 'prep_lc_run'::public.citext) THEN (t_sample_prep_request_items.item_id)::text
            WHEN (t_sample_prep_request_items.item_type OPERATOR(public.=) 'requested_run'::public.citext) THEN (t_sample_prep_request_items.item_id)::text
            ELSE ''::text
        END AS link
   FROM public.t_sample_prep_request_items;


ALTER TABLE public.v_sample_prep_request_items_list_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_items_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_items_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_items_list_report TO writeaccess;

