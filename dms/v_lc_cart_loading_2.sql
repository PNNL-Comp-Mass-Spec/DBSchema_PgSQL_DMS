--
-- Name: v_lc_cart_loading_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_loading_2 AS
 SELECT cart.cart_name AS cart,
    rr.request_name AS name,
    rr.request_id AS request,
    rr.cart_column AS column_number,
    t_experiments.experiment,
    rr.priority,
    dtn.dataset_type AS type,
    rr.batch_id AS batch,
    rr.block,
    rr.run_order,
    eut.eus_usage_type AS emsl_usage_type,
    rr.eus_proposal_id AS emsl_proposal_id,
    public.get_requested_run_eus_users_list(rr.request_id, 'I'::text) AS emsl_user_list
   FROM ((((public.t_requested_run rr
     JOIN public.t_lc_cart cart ON ((rr.cart_id = cart.cart_id)))
     JOIN public.t_experiments ON ((rr.exp_id = t_experiments.exp_id)))
     JOIN public.t_dataset_type_name dtn ON ((rr.request_type_id = dtn.dataset_type_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
  WHERE (rr.state_name OPERATOR(public.=) 'Active'::public.citext);


ALTER TABLE public.v_lc_cart_loading_2 OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_loading_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_loading_2 TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_loading_2 TO writeaccess;

