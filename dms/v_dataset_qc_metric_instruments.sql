--
-- Name: v_dataset_qc_metric_instruments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_qc_metric_instruments AS
 SELECT t_dataset_qc_instruments.instrument,
    t_dataset_qc_instruments.instrument_id
   FROM public.t_dataset_qc_instruments;


ALTER TABLE public.v_dataset_qc_metric_instruments OWNER TO d3l243;

--
-- Name: TABLE v_dataset_qc_metric_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_qc_metric_instruments TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_qc_metric_instruments TO writeaccess;

