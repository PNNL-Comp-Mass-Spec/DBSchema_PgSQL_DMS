--
-- Name: v_myemsl_supplemental_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_myemsl_supplemental_metadata AS
 SELECT ds.dataset_id AS "omics.dms.dataset_id",
    ds.dataset AS "omics.dms.dataset_name",
    e.exp_id AS "omics.dms.experiment_id",
    e.experiment AS "omics.dms.experiment_name",
    c.campaign_id AS "omics.dms.campaign_id",
    c.campaign AS "omics.dms.campaign_name",
    org.organism_id AS "omics.dms.organism_id",
    org.organism AS organism_name,
    org.ncbi_taxonomy_id,
    ds.acq_time_start AS "omics.dms.acquisition_time",
    ds.acq_length_minutes AS "omics.dms.acquisition_length_min",
    ds.scan_count AS "omics.dms.number_of_scans",
    rr.separation_group AS "omics.dms.separation_type",
    dtn.dataset_type AS "omics.dms.dataset_type",
    rr.request_id AS "omics.dms.requested_run_id"
   FROM (((((public.t_campaign c
     LEFT JOIN public.t_experiments e ON ((c.campaign_id = e.campaign_id)))
     LEFT JOIN public.t_dataset ds ON ((e.exp_id = ds.exp_id)))
     LEFT JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)));


ALTER VIEW public.v_myemsl_supplemental_metadata OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_supplemental_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_myemsl_supplemental_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_myemsl_supplemental_metadata TO writeaccess;

