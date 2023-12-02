--
-- Name: v_factor_count_by_experiment; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_factor_count_by_experiment AS
 SELECT experimentfactorq.exp_id,
    sum(
        CASE
            WHEN (experimentfactorq.factor IS NULL) THEN 0
            ELSE 1
        END) AS factor_count
   FROM ( SELECT DISTINCT exp.exp_id,
                CASE
                    WHEN (ds.exp_id IS NULL) THEN exprrfactor.name
                    ELSE dsrrfactor.name
                END AS factor
           FROM ((public.t_experiments exp
             LEFT JOIN ((public.t_dataset ds
             JOIN public.t_requested_run dsrr ON ((ds.dataset_id = dsrr.dataset_id)))
             JOIN public.t_factor dsrrfactor ON (((dsrr.request_id = dsrrfactor.target_id) AND (dsrrfactor.type OPERATOR(public.=) 'Run_Request'::public.citext)))) ON ((exp.exp_id = ds.exp_id)))
             LEFT JOIN (public.t_factor exprrfactor
             JOIN public.t_requested_run exprr ON (((exprrfactor.target_id = exprr.request_id) AND (exprrfactor.type OPERATOR(public.=) 'Run_Request'::public.citext)))) ON ((exp.exp_id = exprr.exp_id)))) experimentfactorq
  GROUP BY experimentfactorq.exp_id;


ALTER VIEW public.v_factor_count_by_experiment OWNER TO d3l243;

--
-- Name: TABLE v_factor_count_by_experiment; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_factor_count_by_experiment TO readaccess;
GRANT SELECT ON TABLE public.v_factor_count_by_experiment TO writeaccess;

