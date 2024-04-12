--
-- Name: t_general_statistics; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_general_statistics (
    entry_id integer NOT NULL,
    category public.citext NOT NULL,
    label public.citext NOT NULL,
    value public.citext,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_general_statistics OWNER TO d3l243;

--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_general_statistics ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_general_statistics_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_general_statistics pk_t_general_statistics; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_general_statistics
    ADD CONSTRAINT pk_t_general_statistics PRIMARY KEY (entry_id);

--
-- Name: ix_t_general_statistics_category_label; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_general_statistics_category_label ON public.t_general_statistics USING btree (category, label);

--
-- Name: TABLE t_general_statistics; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_general_statistics TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_general_statistics TO writeaccess;

