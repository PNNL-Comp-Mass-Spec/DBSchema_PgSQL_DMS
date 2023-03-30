--
-- Name: t_deleted_factor; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_deleted_factor (
    entry_id integer NOT NULL,
    factor_id integer NOT NULL,
    type public.citext DEFAULT 'Run_Request'::public.citext NOT NULL,
    target_id integer NOT NULL,
    name public.citext NOT NULL,
    value public.citext NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    deleted timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_by public.citext
);


ALTER TABLE public.t_deleted_factor OWNER TO d3l243;

--
-- Name: t_deleted_factor_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_deleted_factor ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_deleted_factor_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_deleted_factor pk_t_deleted_factor; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_factor
    ADD CONSTRAINT pk_t_deleted_factor PRIMARY KEY (entry_id);

--
-- Name: ix_t_deleted_factor_type_target_id_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_deleted_factor_type_target_id_name ON public.t_deleted_factor USING btree (type, target_id, name);

--
-- Name: TABLE t_deleted_factor; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_deleted_factor TO readaccess;
GRANT SELECT ON TABLE public.t_deleted_factor TO writeaccess;

