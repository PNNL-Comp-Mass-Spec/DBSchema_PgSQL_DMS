--
-- Name: v_dataset_disposition_lite; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_disposition_lite AS
 SELECT v_dataset_disposition.id,
    v_dataset_disposition.sel,
    v_dataset_disposition.dataset,
    v_dataset_disposition.smaqc,
    v_dataset_disposition.lc_cart,
    v_dataset_disposition.batch,
    v_dataset_disposition.request,
    v_dataset_disposition.rating,
    v_dataset_disposition.comment,
    v_dataset_disposition.state,
    v_dataset_disposition.instrument,
    v_dataset_disposition.created,
    v_dataset_disposition.oper
   FROM public.v_dataset_disposition;


ALTER TABLE public.v_dataset_disposition_lite OWNER TO d3l243;

--
-- Name: TABLE v_dataset_disposition_lite; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_disposition_lite TO readaccess;

