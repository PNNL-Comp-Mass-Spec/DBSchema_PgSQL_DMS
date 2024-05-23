--
-- Name: t_query_row_counts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_query_row_counts (
    query_id integer NOT NULL,
    object_name public.citext NOT NULL,
    where_clause public.citext DEFAULT ''::public.citext NOT NULL,
    row_count bigint DEFAULT 0 NOT NULL,
    last_used timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_refresh timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    refresh_interval_hours numeric DEFAULT 4,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_query_row_counts OWNER TO d3l243;

--
-- Name: t_query_row_counts_query_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_query_row_counts ALTER COLUMN query_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_query_row_counts_query_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_query_row_counts pk_t_query_row_counts; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_query_row_counts
    ADD CONSTRAINT pk_t_query_row_counts PRIMARY KEY (query_id);

--
-- Name: ix_t_query_row_counts_object_name_include_where_clause_row_cnt; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_query_row_counts_object_name_include_where_clause_row_cnt ON public.t_query_row_counts USING btree (object_name) INCLUDE (where_clause, row_count, last_refresh, refresh_interval_hours, query_id);

--
-- Name: TABLE t_query_row_counts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_query_row_counts TO readaccess;
GRANT SELECT ON TABLE public.t_query_row_counts TO writeaccess;

