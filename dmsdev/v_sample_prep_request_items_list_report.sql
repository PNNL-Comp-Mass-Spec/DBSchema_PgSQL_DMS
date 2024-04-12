--
-- Name: v_sample_prep_request_items_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_items_list_report AS
 SELECT prep_request_id AS id,
    item_id,
    item_name,
    item_type,
    status,
    created,
    item_added,
        CASE
            WHEN (item_type OPERATOR(public.=) 'dataset'::public.citext) THEN item_name
            WHEN (item_type OPERATOR(public.=) 'experiment'::public.citext) THEN item_name
            WHEN (item_type OPERATOR(public.=) 'experiment_group'::public.citext) THEN (item_id)::public.citext
            WHEN (item_type OPERATOR(public.=) 'material_container'::public.citext) THEN item_name
            WHEN (item_type OPERATOR(public.=) 'prep_lc_run'::public.citext) THEN (item_id)::public.citext
            WHEN (item_type OPERATOR(public.=) 'requested_run'::public.citext) THEN (item_id)::public.citext
            ELSE ''::public.citext
        END AS link
   FROM public.t_sample_prep_request_items;


ALTER VIEW public.v_sample_prep_request_items_list_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_items_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_items_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_items_list_report TO writeaccess;

