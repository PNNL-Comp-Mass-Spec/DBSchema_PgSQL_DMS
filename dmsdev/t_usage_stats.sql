--
-- Name: t_usage_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_usage_stats (
    posted_by public.citext NOT NULL,
    last_posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usage_count integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_usage_stats OWNER TO d3l243;

--
-- Name: t_usage_stats pk_t_usage_stats; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_usage_stats
    ADD CONSTRAINT pk_t_usage_stats PRIMARY KEY (posted_by);

