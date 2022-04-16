--
-- Name: t_sample_prep_request; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_prep_request (
    prep_request_id integer NOT NULL,
    request_type public.citext NOT NULL,
    request_name public.citext,
    requester_prn public.citext,
    reason public.citext,
    organism public.citext,
    tissue_id public.citext,
    biohazard_level public.citext,
    campaign public.citext,
    number_of_samples integer,
    sample_name_list public.citext,
    sample_type public.citext,
    prep_method public.citext,
    prep_by_robot public.citext,
    special_instructions public.citext,
    sample_naming_convention public.citext,
    assigned_personnel public.citext NOT NULL,
    work_package_number public.citext,
    user_proposal public.citext,
    instrument_group public.citext,
    instrument_name public.citext,
    dataset_type public.citext,
    instrument_analysis_specifications public.citext,
    comment public.citext,
    priority public.citext,
    created timestamp without time zone NOT NULL,
    state smallint NOT NULL,
    state_comment public.citext,
    requested_personnel public.citext,
    state_changed timestamp without time zone NOT NULL,
    internal_standard_id integer NOT NULL,
    post_digest_internal_std_id integer NOT NULL,
    estimated_completion timestamp without time zone,
    estimated_prep_time_days integer NOT NULL,
    estimated_ms_runs public.citext,
    eus_usage_type public.citext,
    eus_proposal_id public.citext,
    eus_user_id integer,
    project_number public.citext,
    facility public.citext NOT NULL,
    separation_type public.citext,
    block_and_randomize_samples character(3),
    block_and_randomize_runs character(3),
    reason_for_high_priority public.citext,
    sample_submission_item_count integer,
    biomaterial_item_count integer,
    experiment_item_count integer,
    experiment_group_item_count integer,
    material_containers_item_count integer,
    requested_run_item_count integer,
    dataset_item_count integer,
    hplc_runs_item_count integer,
    total_item_count integer,
    material_container_list public.citext,
    assigned_personnel_sort_key public.citext GENERATED ALWAYS AS (
CASE
    WHEN (assigned_personnel OPERATOR(public.=) 'na'::public.citext) THEN 'zz_na'::text
    ELSE "left"((assigned_personnel)::text, 64)
END) STORED
);


ALTER TABLE public.t_sample_prep_request OWNER TO d3l243;

--
-- Name: TABLE t_sample_prep_request; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request TO readaccess;

