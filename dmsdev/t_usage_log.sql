--
-- Name: t_usage_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_usage_log (
    entry_id integer NOT NULL,
    posted_by public.citext NOT NULL,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message public.citext,
    calling_user public.citext,
    usage_count integer
);


ALTER TABLE public.t_usage_log OWNER TO d3l243;

--
-- Name: t_usage_log_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_usage_log ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_usage_log_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_usage_log pk_t_usage_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_usage_log
    ADD CONSTRAINT pk_t_usage_log PRIMARY KEY (entry_id);

--
-- Name: ix_t_usage_log_calling_user; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_usage_log_calling_user ON public.t_usage_log USING btree (calling_user);

--
-- Name: ix_t_usage_log_posted_by; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_usage_log_posted_by ON public.t_usage_log USING btree (posted_by);

--
-- Name: TABLE t_usage_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_usage_log TO readaccess;

