--
-- Name: v_dataset_validation_warnings; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_validation_warnings AS
 SELECT ds.dataset_id,
    ds.dataset,
    ds.created,
    instname.instrument,
    rr.request_id AS requested_run_id,
    ds.lc_column_id,
    ds.dataset_type_id,
    ds.separation_type,
        CASE
            WHEN (rr.request_id IS NULL) THEN 'Dataset does not have a requested run; create one'::public.citext
            WHEN (ds.lc_column_id IS NULL) THEN 'LC Column ID is null'::public.citext
            WHEN (ds.dataset_type_id IS NULL) THEN 'Dataset Type ID is null'::public.citext
            WHEN (ds.separation_type IS NULL) THEN 'Separation_Type is null'::public.citext
            ELSE 'Unknown Error'::public.citext
        END AS warning
   FROM ((public.t_dataset ds
     LEFT JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
  WHERE ((ds.created >= '2015-01-01 00:00:00'::timestamp without time zone) AND ((rr.request_id IS NULL) OR (ds.instrument_id IS NULL) OR (ds.lc_column_id IS NULL) OR (ds.dataset_type_id IS NULL) OR (ds.separation_type IS NULL)));


ALTER TABLE public.v_dataset_validation_warnings OWNER TO d3l243;

--
-- Name: TABLE v_dataset_validation_warnings; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_validation_warnings TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_validation_warnings TO writeaccess;

