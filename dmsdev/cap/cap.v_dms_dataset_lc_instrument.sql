--
-- Name: v_dms_dataset_lc_instrument; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_dataset_lc_instrument AS
 SELECT ds.dataset,
    ds.dataset_id,
    lcc.cart_name AS lc_cart_name,
    instname.instrument AS lc_instrument_name,
    instname.instrument_class AS lc_instrument_class,
    instname.instrument_group AS lc_instrument_group,
    instname.capture_method AS lc_instrument_capture_method,
    spath.vol_name_server AS source_vol,
    spath.storage_path AS source_path
   FROM ((((public.t_dataset ds
     JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     JOIN public.t_lc_cart lcc ON ((rr.cart_id = lcc.cart_id)))
     LEFT JOIN public.t_instrument_name instname ON ((lcc.cart_name OPERATOR(public.=) instname.instrument)))
     LEFT JOIN public.t_storage_path spath ON ((instname.source_path_id = spath.storage_path_id)));


ALTER VIEW cap.v_dms_dataset_lc_instrument OWNER TO d3l243;

--
-- Name: TABLE v_dms_dataset_lc_instrument; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_dataset_lc_instrument TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_dataset_lc_instrument TO writeaccess;

