--
-- Name: v_experiment_count_by_month; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_count_by_month AS
 SELECT v_experiment_date.year,
    v_experiment_date.month,
    count(v_experiment_date.experiment) AS number_of_experiments_created,
    (((v_experiment_date.month)::text || '/'::text) || (v_experiment_date.year)::text) AS date
   FROM public.v_experiment_date
  GROUP BY v_experiment_date.year, v_experiment_date.month;


ALTER VIEW public.v_experiment_count_by_month OWNER TO d3l243;

--
-- Name: TABLE v_experiment_count_by_month; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_count_by_month TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_count_by_month TO writeaccess;

