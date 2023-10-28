--
-- Name: v_dms_dataset_lc_instrument; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_dataset_lc_instrument AS
 SELECT ds.dataset,
    ds.dataset_id,
    lcc.cart_name AS lc_cart_name,
    tin.instrument AS lc_instrument_name,
    tin.instrument_class AS lc_instrument_class,
    tin.instrument_group AS lc_instrument_group,
    tin.capture_method AS lc_instrument_capture_method,
    tsp.vol_name_server AS source_vol,
    tsp.storage_path AS source_path
   FROM ((((public.t_dataset ds
     JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     JOIN public.t_lc_cart lcc ON ((rr.cart_id = lcc.cart_id)))
     LEFT JOIN public.t_instrument_name tin ON ((lcc.cart_name OPERATOR(public.=) tin.instrument)))
     JOIN public.t_storage_path tsp ON ((tin.source_path_id = tsp.storage_path_id)));


ALTER TABLE cap.v_dms_dataset_lc_instrument OWNER TO d3l243;

--
-- Name: TABLE v_dms_dataset_lc_instrument; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_dataset_lc_instrument TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_dataset_lc_instrument TO writeaccess;

