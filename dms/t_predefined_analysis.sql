--
-- Name: t_predefined_analysis; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis (
    predefine_id integer NOT NULL,
    predefine_level integer NOT NULL,
    predefine_sequence integer,
    instrument_class_criteria public.citext NOT NULL,
    instrument_name_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    instrument_excl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    campaign_name_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    campaign_excl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    experiment_name_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    experiment_excl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    exp_comment_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    organism_name_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    dataset_name_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    dataset_excl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    dataset_type_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    scan_type_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    scan_type_excl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    labelling_incl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    labelling_excl_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    separation_type_criteria public.citext DEFAULT ''::public.citext NOT NULL,
    scan_count_min_criteria integer DEFAULT 0 NOT NULL,
    scan_count_max_criteria integer DEFAULT 0 NOT NULL,
    analysis_tool_name public.citext NOT NULL,
    param_file_name public.citext NOT NULL,
    settings_file_name public.citext,
    organism_id integer NOT NULL,
    organism_db_name public.citext DEFAULT 'default'::public.citext NOT NULL,
    protein_collection_list public.citext DEFAULT 'na'::public.citext NOT NULL,
    protein_options_list public.citext DEFAULT 'na'::public.citext NOT NULL,
    priority integer DEFAULT 2 NOT NULL,
    special_processing public.citext,
    enabled smallint DEFAULT 0 NOT NULL,
    description public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    creator public.citext,
    next_level integer,
    trigger_before_disposition smallint DEFAULT 0 NOT NULL,
    propagation_mode smallint DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
-- Name: t_predefined_analysis trig_t_predefined_analysis_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_predefined_analysis_after_update AFTER UPDATE ON public.t_predefined_analysis FOR EACH ROW WHEN (((old.predefine_level <> new.predefine_level) OR (old.predefine_sequence IS DISTINCT FROM new.predefine_sequence) OR (old.instrument_class_criteria OPERATOR(public.<>) new.instrument_class_criteria) OR (old.instrument_name_criteria OPERATOR(public.<>) new.instrument_name_criteria) OR (old.instrument_excl_criteria OPERATOR(public.<>) new.instrument_excl_criteria) OR (old.campaign_excl_criteria OPERATOR(public.<>) new.campaign_excl_criteria) OR (old.campaign_name_criteria OPERATOR(public.<>) new.campaign_name_criteria) OR (old.experiment_excl_criteria OPERATOR(public.<>) new.experiment_excl_criteria) OR (old.experiment_name_criteria OPERATOR(public.<>) new.experiment_name_criteria) OR (old.exp_comment_criteria OPERATOR(public.<>) new.exp_comment_criteria) OR (old.organism_name_criteria OPERATOR(public.<>) new.organism_name_criteria) OR (old.dataset_name_criteria OPERATOR(public.<>) new.dataset_name_criteria) OR (old.dataset_excl_criteria OPERATOR(public.<>) new.dataset_excl_criteria) OR (old.dataset_type_criteria OPERATOR(public.<>) new.dataset_type_criteria) OR (old.scan_type_criteria OPERATOR(public.<>) new.scan_type_criteria) OR (old.scan_type_excl_criteria OPERATOR(public.<>) new.scan_type_excl_criteria) OR (old.labelling_excl_criteria OPERATOR(public.<>) new.labelling_excl_criteria) OR (old.labelling_incl_criteria OPERATOR(public.<>) new.labelling_incl_criteria) OR (old.separation_type_criteria OPERATOR(public.<>) new.separation_type_criteria) OR (old.scan_count_min_criteria <> new.scan_count_min_criteria) OR (old.scan_count_max_criteria <> new.scan_count_max_criteria) OR (old.analysis_tool_name OPERATOR(public.<>) new.analysis_tool_name) OR (old.param_file_name OPERATOR(public.<>) new.param_file_name) OR ((old.settings_file_name)::text IS DISTINCT FROM (new.settings_file_name)::text) OR (old.organism_id <> new.organism_id) OR (old.organism_db_name OPERATOR(public.<>) new.organism_db_name) OR (old.protein_collection_list OPERATOR(public.<>) new.protein_collection_list) OR (old.protein_options_list OPERATOR(public.<>) new.protein_options_list) OR (old.priority <> new.priority) OR ((old.special_processing)::text IS DISTINCT FROM (new.special_processing)::text) OR (old.enabled <> new.enabled) OR ((old.description)::text IS DISTINCT FROM (new.description)::text) OR (old.next_level IS DISTINCT FROM new.next_level) OR (old.trigger_before_disposition <> new.trigger_before_disposition) OR (old.propagation_mode <> new.propagation_mode))) EXECUTE FUNCTION public.trigfn_t_predefined_analysis_after_update();

--
-- Name: t_predefined_analysis fk_t_predefined_analysis_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis
    ADD CONSTRAINT fk_t_predefined_analysis_t_analysis_tool FOREIGN KEY (analysis_tool_name) REFERENCES public.t_analysis_tool(analysis_tool);

--
-- Name: t_predefined_analysis fk_t_predefined_analysis_t_instrument_class; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis
    ADD CONSTRAINT fk_t_predefined_analysis_t_instrument_class FOREIGN KEY (instrument_class_criteria) REFERENCES public.t_instrument_class(instrument_class);

--
-- Name: t_predefined_analysis fk_t_predefined_analysis_t_organisms; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis
    ADD CONSTRAINT fk_t_predefined_analysis_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: TABLE t_predefined_analysis; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis TO readaccess;
GRANT SELECT ON TABLE public.t_predefined_analysis TO writeaccess;

