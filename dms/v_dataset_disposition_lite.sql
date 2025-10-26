--
-- Name: v_dataset_disposition_lite; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_disposition_lite AS
 SELECT id,
    sel,
    dataset,
    smaqc,
    lc_cart,
    batch,
    work_package,
    rating,
    comment,
    state,
    instrument,
    acq_time_start,
    request,
    operator,
    created
   FROM public.v_dataset_disposition;


ALTER VIEW public.v_dataset_disposition_lite OWNER TO d3l243;

--
-- Name: TABLE v_dataset_disposition_lite; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_disposition_lite TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_disposition_lite TO writeaccess;

