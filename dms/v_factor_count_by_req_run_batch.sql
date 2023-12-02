--
-- Name: v_factor_count_by_req_run_batch; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_factor_count_by_req_run_batch AS
 SELECT factorq.batch_id,
    sum(
        CASE
            WHEN (factorq.factor IS NULL) THEN 0
            ELSE 1
        END) AS factor_count
   FROM ( SELECT DISTINCT rrb.batch_id,
            rrfactor.name AS factor
           FROM ((public.t_factor rrfactor
             JOIN public.t_requested_run rr ON (((rrfactor.target_id = rr.request_id) AND (rrfactor.type OPERATOR(public.=) 'Run_Request'::public.citext))))
             JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)))
          WHERE (rrb.batch_id <> 0)) factorq
  GROUP BY factorq.batch_id;


ALTER VIEW public.v_factor_count_by_req_run_batch OWNER TO d3l243;

--
-- Name: TABLE v_factor_count_by_req_run_batch; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_factor_count_by_req_run_batch TO readaccess;
GRANT SELECT ON TABLE public.v_factor_count_by_req_run_batch TO writeaccess;

