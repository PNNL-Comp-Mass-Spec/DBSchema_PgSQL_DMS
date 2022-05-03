--
-- Name: t_project_usage_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_project_usage_stats (
    entry_id integer NOT NULL,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    the_year integer NOT NULL,
    week_of_year smallint NOT NULL,
    proposal_id public.citext,
    work_package public.citext,
    proposal_active integer NOT NULL,
    project_type_id smallint NOT NULL,
    samples integer,
    datasets integer,
    jobs integer,
    eus_usage_type_id smallint NOT NULL,
    proposal_type public.citext,
    proposal_user public.citext,
    instrument_first public.citext,
    instrument_last public.citext,
    job_tool_first public.citext,
    job_tool_last public.citext,
    sort_key public.citext GENERATED ALWAYS AS (((((the_year * 10000) + week_of_year))::double precision + (((datasets + jobs))::double precision / (10000000)::double precision))) STORED
);


ALTER TABLE public.t_project_usage_stats OWNER TO d3l243;

--
-- Name: t_project_usage_stats_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_project_usage_stats ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_project_usage_stats_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_project_usage_stats pk_t_project_usage_stats; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_project_usage_stats
    ADD CONSTRAINT pk_t_project_usage_stats PRIMARY KEY (entry_id);

--
-- Name: ix_t_project_usage_stats_year_and_week; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_project_usage_stats_year_and_week ON public.t_project_usage_stats USING btree (the_year, week_of_year);

--
-- Name: TABLE t_project_usage_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_project_usage_stats TO readaccess;

