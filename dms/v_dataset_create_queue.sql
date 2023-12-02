--
-- Name: v_dataset_create_queue; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_create_queue AS
 SELECT dcq.entry_id,
    dcq.state_id,
    qs.queue_state_name,
    dcq.dataset,
    dcq.experiment,
    dcq.instrument,
    dcq.separation_type,
    dcq.lc_cart,
    dcq.lc_cart_config,
    dcq.lc_column,
    dcq.wellplate,
    dcq.well,
    dcq.dataset_type,
    dcq.operator_username,
    dcq.ds_creator_username,
    dcq.comment,
    dcq.interest_rating,
    dcq.request,
    dcq.work_package,
    dcq.eus_usage_type,
    dcq.eus_proposal_id,
    dcq.eus_users,
    dcq.capture_share_name,
    dcq.capture_subdirectory,
    dcq.command,
    dcq.processor,
    dcq.created,
    dcq.start,
    dcq.finish,
    dcq.completion_code,
    dcq.completion_message
   FROM (public.t_dataset_create_queue dcq
     JOIN public.t_dataset_create_queue_state qs ON ((dcq.state_id = qs.queue_state_id)));


ALTER VIEW public.v_dataset_create_queue OWNER TO d3l243;

--
-- Name: TABLE v_dataset_create_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_create_queue TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_create_queue TO writeaccess;

