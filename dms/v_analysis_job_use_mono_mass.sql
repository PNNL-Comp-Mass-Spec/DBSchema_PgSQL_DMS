--
-- Name: v_analysis_job_use_mono_mass; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_use_mono_mass AS
 SELECT t_dataset.dataset_id,
    t_dataset.dataset AS dataset_name,
    t_dataset_type_name.dataset_type,
        CASE
            WHEN (t_dataset_type_name.dataset_type OPERATOR(public.~~) 'HMS%'::public.citext) THEN 1
            WHEN (t_dataset_type_name.dataset_type OPERATOR(public.~~) 'IMS%'::public.citext) THEN 1
            ELSE 0
        END AS use_mono_parent
   FROM (public.t_dataset
     JOIN public.t_dataset_type_name ON ((t_dataset.dataset_type_id = t_dataset_type_name.dataset_type_id)));


ALTER VIEW public.v_analysis_job_use_mono_mass OWNER TO d3l243;

--
-- Name: VIEW v_analysis_job_use_mono_mass; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_analysis_job_use_mono_mass IS 'This view is used by the ParamFileGenerator to determine whether to auto-enable monoisotopic masses when generating Sequest param files';

--
-- Name: TABLE v_analysis_job_use_mono_mass; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_use_mono_mass TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_use_mono_mass TO writeaccess;

