--
-- Name: t_sp_usage; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_sp_usage (
    entry_id integer NOT NULL,
    posted_by public.citext NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processor_id integer,
    calling_user public.citext
);


ALTER TABLE sw.t_sp_usage OWNER TO d3l243;

--
-- Name: t_sp_usage_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_sp_usage ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_sp_usage_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sp_usage pk_t_sp_usage; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_sp_usage
    ADD CONSTRAINT pk_t_sp_usage PRIMARY KEY (entry_id);

