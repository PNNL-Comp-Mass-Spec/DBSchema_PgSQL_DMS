--
-- Name: t_material_containers; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_containers (
    container_id integer NOT NULL,
    container public.citext NOT NULL,
    type public.citext NOT NULL,
    comment public.citext,
    barcode public.citext,
    location_id integer NOT NULL,
    created timestamp without time zone NOT NULL,
    status public.citext NOT NULL,
    researcher public.citext
);


ALTER TABLE public.t_material_containers OWNER TO d3l243;

--
-- Name: TABLE t_material_containers; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_containers TO readaccess;

