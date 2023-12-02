--
-- Name: v_dataset_disposition; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_disposition AS
 SELECT ds.dataset_id AS id,
    ''::text AS sel,
    ds.dataset,
    (((((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/QC/'::text) || (ds.dataset)::text) || '_BPI_MS.png'::text) AS qc_link,
    ('http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/'::text || (instname.instrument)::text) AS smaqc,
    lcc.cart_name AS lc_cart,
    rr.batch_id AS batch,
    rr.request_id AS request,
    drn.dataset_rating AS rating,
    ds.comment,
    dsn.dataset_state AS state,
    instname.instrument,
    ds.created,
    ds.operator_username AS operator
   FROM (((public.t_lc_cart lcc
     JOIN public.t_requested_run rr ON ((lcc.cart_id = rr.cart_id)))
     RIGHT JOIN (((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id))) ON ((rr.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((spath.storage_path_id = ds.storage_path_id)))
  WHERE (ds.dataset_rating_id = '-10'::integer);


ALTER VIEW public.v_dataset_disposition OWNER TO d3l243;

--
-- Name: TABLE v_dataset_disposition; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_disposition TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_disposition TO writeaccess;

