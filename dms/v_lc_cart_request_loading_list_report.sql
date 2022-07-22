--
-- Name: v_lc_cart_request_loading_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_request_loading_list_report AS
 SELECT rr.batch_id,
    rrb.locked,
    rr.request_id AS request,
    rr.request_name AS name,
    rr.state_name AS status,
    rr.instrument_group AS instrument,
    rr.separation_group AS separation_type,
    e.experiment,
    rr.block,
    lccart.cart_name AS cart,
    cartconfig.cart_config_name AS cart_config,
    rr.cart_column AS col
   FROM ((((public.t_requested_run rr
     JOIN public.t_lc_cart lccart ON ((rr.cart_id = lccart.cart_id)))
     JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((rr.cart_config_id = cartconfig.cart_config_id)))
  WHERE (rr.state_name OPERATOR(public.=) 'Active'::public.citext);


ALTER TABLE public.v_lc_cart_request_loading_list_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_request_loading_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_request_loading_list_report TO readaccess;

