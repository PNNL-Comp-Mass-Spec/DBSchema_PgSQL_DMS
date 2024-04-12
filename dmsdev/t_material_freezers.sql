--
-- Name: t_material_freezers; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_freezers (
    freezer_id integer NOT NULL,
    freezer public.citext NOT NULL,
    freezer_tag public.citext NOT NULL,
    comment public.citext,
    CONSTRAINT ck_t_material_freezers_freezer_tag_whitespace CHECK ((public.has_whitespace_chars((freezer_tag)::text, false) = false))
);


ALTER TABLE public.t_material_freezers OWNER TO d3l243;

--
-- Name: t_material_freezers_freezer_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_material_freezers ALTER COLUMN freezer_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_material_freezers_freezer_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_material_freezers pk_t_material_freezers; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_freezers
    ADD CONSTRAINT pk_t_material_freezers PRIMARY KEY (freezer_id);

--
-- Name: ix_t_material_freezers_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_material_freezers_name ON public.t_material_freezers USING btree (freezer);

--
-- Name: ix_t_material_freezers_tag; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_material_freezers_tag ON public.t_material_freezers USING btree (freezer_tag);

--
-- Name: TABLE t_material_freezers; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_freezers TO readaccess;
GRANT SELECT ON TABLE public.t_material_freezers TO writeaccess;

