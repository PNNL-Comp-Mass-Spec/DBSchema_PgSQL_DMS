--
-- Name: v_requested_run_batch_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_picklist AS
 SELECT batch_id AS id,
    batch,
    (((((((batch_id)::public.citext)::text || (': '::public.citext)::text))::public.citext)::text || (batch)::text))::public.citext AS id_with_batch
   FROM public.t_requested_run_batches;


ALTER VIEW public.v_requested_run_batch_picklist OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_picklist TO writeaccess;

