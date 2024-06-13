--
-- Name: t_query_row_count_default_refresh_interval; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_query_row_count_default_refresh_interval (
    entry_id integer NOT NULL,
    object_name public.citext NOT NULL,
    refresh_interval_hours numeric DEFAULT 4 NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_query_row_count_default_refresh_interval OWNER TO d3l243;

--
-- Name: t_query_row_count_default_refresh_interval_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_query_row_count_default_refresh_interval ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_query_row_count_default_refresh_interval_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_query_row_count_default_refresh_interval pk_t_query_row_count_default_refresh_interval; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_query_row_count_default_refresh_interval
    ADD CONSTRAINT pk_t_query_row_count_default_refresh_interval PRIMARY KEY (entry_id);

--
-- Name: ix_t_query_row_count_default_refresh_interval_object_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_query_row_count_default_refresh_interval_object_name ON public.t_query_row_count_default_refresh_interval USING btree (object_name);

--
-- Name: TABLE t_query_row_count_default_refresh_interval; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_query_row_count_default_refresh_interval TO readaccess;
GRANT SELECT,INSERT,UPDATE ON TABLE public.t_query_row_count_default_refresh_interval TO writeaccess;

