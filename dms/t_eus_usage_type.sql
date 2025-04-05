--
-- Name: t_eus_usage_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_usage_type (
    eus_usage_type_id smallint NOT NULL,
    eus_usage_type public.citext NOT NULL,
    description public.citext,
    enabled smallint DEFAULT 1 NOT NULL,
    enabled_campaign smallint DEFAULT 1 NOT NULL,
    enabled_prep_request smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_eus_usage_type OWNER TO d3l243;

--
-- Name: t_eus_usage_type_eus_usage_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_eus_usage_type ALTER COLUMN eus_usage_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_eus_usage_type_eus_usage_type_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_eus_usage_type pk_t_eus_usage_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_usage_type
    ADD CONSTRAINT pk_t_eus_usage_type PRIMARY KEY (eus_usage_type_id);

ALTER TABLE public.t_eus_usage_type CLUSTER ON pk_t_eus_usage_type;

--
-- Name: ix_t_eus_usage_type_eus_usage_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_eus_usage_type_eus_usage_type ON public.t_eus_usage_type USING btree (eus_usage_type);

--
-- Name: TABLE t_eus_usage_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_usage_type TO readaccess;
GRANT SELECT ON TABLE public.t_eus_usage_type TO writeaccess;

