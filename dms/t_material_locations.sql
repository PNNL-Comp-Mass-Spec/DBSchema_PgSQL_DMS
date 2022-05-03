--
-- Name: t_material_locations; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_locations (
    location_id integer NOT NULL,
    freezer_tag public.citext NOT NULL,
    shelf public.citext NOT NULL,
    rack public.citext NOT NULL,
    "row" public.citext NOT NULL,
    col public.citext NOT NULL,
    status public.citext NOT NULL,
    barcode public.citext,
    comment public.citext,
    container_limit integer NOT NULL,
    tag public.citext GENERATED ALWAYS AS (
CASE
    WHEN (freezer_tag OPERATOR(public.=) ANY (ARRAY['QC_Staging'::public.citext, 'Phosphopep_Staging'::public.citext, '-80_Staging'::public.citext, '-20_Met_Staging'::public.citext, '-20_Staging_1206'::public.citext, '-20_Staging'::public.citext, 'None'::public.citext])) THEN (freezer_tag)::text
    ELSE (((((((((freezer_tag)::text || '.'::text) || (shelf)::text) || '.'::text) || (rack)::text) || '.'::text) || ("row")::text) || '.'::text) || (col)::text)
END) STORED
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
-- Name: TABLE t_material_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_locations TO readaccess;

