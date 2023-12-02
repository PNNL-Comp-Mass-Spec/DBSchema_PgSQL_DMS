--
-- Name: v_factor_count_by_dataset; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_factor_count_by_dataset AS
 SELECT factorq.dataset_id,
    sum(
        CASE
            WHEN (factorq.factor IS NULL) THEN 0
            ELSE 1
        END) AS factor_count
   FROM ( SELECT DISTINCT ds.dataset_id,
            f.name AS factor
           FROM ((public.t_factor f
             JOIN public.t_requested_run rr ON ((f.target_id = rr.request_id)))
             RIGHT JOIN public.t_dataset ds ON (((f.type OPERATOR(public.=) 'Run_Request'::public.citext) AND (rr.dataset_id = ds.dataset_id))))) factorq
  GROUP BY factorq.dataset_id;


ALTER VIEW public.v_factor_count_by_dataset OWNER TO d3l243;

--
-- Name: TABLE v_factor_count_by_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_factor_count_by_dataset TO readaccess;
GRANT SELECT ON TABLE public.v_factor_count_by_dataset TO writeaccess;

