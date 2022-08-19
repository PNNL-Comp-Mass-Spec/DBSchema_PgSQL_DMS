--
-- Name: v_requested_run_batch_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_picklist AS
 SELECT t_requested_run_batches.batch_id AS id,
    t_requested_run_batches.batch,
    (((t_requested_run_batches.batch_id)::text || ': '::text) || (t_requested_run_batches.batch)::text) AS id_with_batch
   FROM public.t_requested_run_batches;


ALTER TABLE public.v_requested_run_batch_picklist OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_picklist TO writeaccess;

