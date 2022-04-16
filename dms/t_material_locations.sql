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
-- Name: TABLE t_material_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_locations TO readaccess;

