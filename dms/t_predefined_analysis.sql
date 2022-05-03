--
-- Name: t_predefined_analysis; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis (
    predefine_id integer NOT NULL,
    predefine_level integer NOT NULL,
    predefine_sequence integer,
    instrument_class_criteria public.citext NOT NULL,
    campaign_name_criteria public.citext NOT NULL,
    campaign_excl_criteria public.citext NOT NULL,
    experiment_name_criteria public.citext NOT NULL,
    experiment_excl_criteria public.citext NOT NULL,
    instrument_name_criteria public.citext NOT NULL,
    instrument_excl_criteria public.citext NOT NULL,
    organism_name_criteria public.citext NOT NULL,
    dataset_name_criteria public.citext NOT NULL,
    dataset_excl_criteria public.citext NOT NULL,
    dataset_type_criteria public.citext NOT NULL,
    exp_comment_criteria public.citext NOT NULL,
    labelling_incl_criteria public.citext NOT NULL,
    labelling_excl_criteria public.citext NOT NULL,
    separation_type_criteria public.citext NOT NULL,
    scan_count_min_criteria integer NOT NULL,
    scan_count_max_criteria integer NOT NULL,
    analysis_tool_name public.citext NOT NULL,
    param_file_name public.citext NOT NULL,
    settings_file_name public.citext,
    organism_id integer NOT NULL,
    organism_db_name public.citext NOT NULL,
    protein_collection_list public.citext NOT NULL,
    protein_options_list public.citext NOT NULL,
    priority integer NOT NULL,
    special_processing public.citext,
    enabled smallint NOT NULL,
    description public.citext,
    created timestamp without time zone NOT NULL,
    creator public.citext,
    next_level integer,
    trigger_before_disposition smallint NOT NULL,
    propagation_mode smallint NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_predefined_analysis OWNER TO d3l243;

--
-- Name: t_predefined_analysis_predefine_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_predefined_analysis ALTER COLUMN predefine_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_predefined_analysis_predefine_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_predefined_analysis pk_t_predefined_analysis; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis
    ADD CONSTRAINT pk_t_predefined_analysis PRIMARY KEY (predefine_id);

--
-- Name: TABLE t_predefined_analysis; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis TO readaccess;

