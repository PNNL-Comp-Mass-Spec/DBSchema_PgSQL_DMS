--
-- Name: v_experiment_date; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_date AS
 SELECT t_experiments.experiment,
    EXTRACT(year FROM t_experiments.created) AS year,
    EXTRACT(month FROM t_experiments.created) AS month,
    EXTRACT(day FROM t_experiments.created) AS day
   FROM public.t_experiments;


ALTER VIEW public.v_experiment_date OWNER TO d3l243;

--
-- Name: TABLE v_experiment_date; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_date TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_date TO writeaccess;

