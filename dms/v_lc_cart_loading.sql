--
-- Name: v_lc_cart_loading; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_loading AS
 SELECT rr.request_id AS request,
    ''::text AS sel,
    rr.request_name AS name,
    cart.cart_name AS lc_cart,
    rr.cart_column AS "column",
    rr.instrument_group AS instrument,
    dtn.dataset_type AS type,
    rr.batch_id AS batch,
    rr.block,
    rr.run_order,
    public.merge_text_three_items((rr.instrument_setting)::text, (rr.special_instructions)::text, (rr.comment)::text) AS comment,
    e.experiment,
    rr.priority,
    u.name AS requester,
    rr.created
   FROM ((((public.t_requested_run rr
     JOIN public.t_users u ON ((rr.requester_prn OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_lc_cart cart ON ((rr.cart_id = cart.cart_id)))
     JOIN public.t_dataset_type_name dtn ON ((rr.request_type_id = dtn.dataset_type_id)));


ALTER TABLE public.v_lc_cart_loading OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_loading; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_loading TO readaccess;

