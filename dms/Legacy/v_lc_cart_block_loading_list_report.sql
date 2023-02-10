--
-- Name: v_lc_cart_block_loading_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_block_loading_list_report AS
 SELECT rr.batch_id,
    rrb.batch,
    rr.block,
    count(rr.request_id) AS requests,
    public.get_requested_run_block_cart_assignment(rr.batch_id, rr.block, 'cart'::text) AS cart,
    public.get_requested_run_block_cart_assignment(rr.batch_id, rr.block, 'col'::text) AS col,
    (((rr.batch_id)::text || '.'::text) || COALESCE((rr.block)::text, ''::text)) AS "#idx"
   FROM (public.t_requested_run rr
     JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)))
  WHERE ((rr.state_name OPERATOR(public.=) 'Active'::public.citext) AND (rr.batch_id <> 0))
  GROUP BY rr.batch_id, rr.block, rrb.batch, rr.state_name;


ALTER TABLE public.v_lc_cart_block_loading_list_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_block_loading_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_block_loading_list_report TO readaccess;

