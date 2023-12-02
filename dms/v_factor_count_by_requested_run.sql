--
-- Name: v_factor_count_by_requested_run; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_factor_count_by_requested_run AS
 SELECT factorq.rr_id,
    sum(
        CASE
            WHEN (factorq.factor IS NULL) THEN 0
            ELSE 1
        END) AS factor_count
   FROM ( SELECT DISTINCT rr.request_id AS rr_id,
            rrfactor.name AS factor
           FROM (public.t_factor rrfactor
             JOIN public.t_requested_run rr ON (((rrfactor.target_id = rr.request_id) AND (rrfactor.type OPERATOR(public.=) 'Run_Request'::public.citext))))) factorq
  GROUP BY factorq.rr_id;


ALTER VIEW public.v_factor_count_by_requested_run OWNER TO d3l243;

--
-- Name: TABLE v_factor_count_by_requested_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_factor_count_by_requested_run TO readaccess;
GRANT SELECT ON TABLE public.v_factor_count_by_requested_run TO writeaccess;

