--
-- Name: t_material_locations; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_locations (
    location_id integer NOT NULL,
    freezer_tag public.citext DEFAULT 'None'::public.citext NOT NULL,
    shelf public.citext DEFAULT 'na'::public.citext NOT NULL,
    rack public.citext DEFAULT 'na'::public.citext NOT NULL,
    "row" public.citext DEFAULT 'na'::public.citext NOT NULL,
    col public.citext DEFAULT 'na'::public.citext NOT NULL,
    status public.citext DEFAULT 'Active'::public.citext NOT NULL,
    barcode public.citext,
    comment public.citext,
    container_limit integer DEFAULT 1 NOT NULL,
    location public.citext GENERATED ALWAYS AS (
CASE
    WHEN ((freezer_tag OPERATOR(public.~~) '%Staging%'::public.citext) OR (freezer_tag OPERATOR(public.=) 'None'::public.citext)) THEN (freezer_tag)::text
    ELSE (((((((((freezer_tag)::text || '.'::text) || (shelf)::text) || '.'::text) || (rack)::text) || '.'::text) || ("row")::text) || '.'::text) || (col)::text)
END) STORED,
    rfid_hex_id public.citext GENERATED ALWAYS AS ("left"(upper((encode((('ML'::text || (location_id)::text))::bytea, 'hex'::text) || '000000000000000000000000'::text)), 24)) STORED,
    CONSTRAINT ck_t_material_locations_status CHECK (((status OPERATOR(public.=) 'Inactive'::public.citext) OR (status OPERATOR(public.=) 'active'::public.citext)))
);


ALTER TABLE public.t_material_locations OWNER TO d3l243;

--
-- Name: t_material_locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_material_locations ALTER COLUMN location_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_material_locations_location_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_material_locations pk_t_material_locations; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_locations
    ADD CONSTRAINT pk_t_material_locations PRIMARY KEY (location_id);

--
-- Name: ix_t_material_locations_id_include_location; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_material_locations_id_include_location ON public.t_material_locations USING btree (location_id) INCLUDE (location);

--
-- Name: ix_t_material_locations_location; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_material_locations_location ON public.t_material_locations USING btree (location);

--
-- Name: t_material_locations fk_t_material_locations_t_material_freezers; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_locations
    ADD CONSTRAINT fk_t_material_locations_t_material_freezers FOREIGN KEY (freezer_tag) REFERENCES public.t_material_freezers(freezer_tag) ON UPDATE CASCADE;

--
-- Name: TABLE t_material_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_locations TO readaccess;
GRANT SELECT ON TABLE public.t_material_locations TO writeaccess;

