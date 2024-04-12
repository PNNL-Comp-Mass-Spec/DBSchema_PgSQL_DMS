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
-- Name: ix_t_usage_log_posted_by_calling_user_include_posting_time; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_usage_log_posted_by_calling_user_include_posting_time ON public.t_usage_log USING btree (posted_by, calling_user) INCLUDE (posting_time);

--
-- Name: TABLE t_usage_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_usage_log TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_usage_log TO writeaccess;

--
-- Name: COLUMN t_usage_log.posting_time; Type: ACL; Schema: public; Owner: d3l243
--

GRANT UPDATE(posting_time) ON TABLE public.t_usage_log TO writeaccess;

--
-- Name: COLUMN t_usage_log.message; Type: ACL; Schema: public; Owner: d3l243
--

GRANT UPDATE(message) ON TABLE public.t_usage_log TO writeaccess;

--
-- Name: COLUMN t_usage_log.calling_user; Type: ACL; Schema: public; Owner: d3l243
--

GRANT UPDATE(calling_user) ON TABLE public.t_usage_log TO writeaccess;

--
-- Name: COLUMN t_usage_log.usage_count; Type: ACL; Schema: public; Owner: d3l243
--

GRANT UPDATE(usage_count) ON TABLE public.t_usage_log TO writeaccess;

