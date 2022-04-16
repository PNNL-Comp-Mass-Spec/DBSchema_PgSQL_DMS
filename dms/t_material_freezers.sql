--
-- Name: t_material_freezers; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_freezers (
    freezer_id integer NOT NULL,
    freezer public.citext NOT NULL,
    freezer_tag public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_material_freezers OWNER TO d3l243;

--
-- Name: TABLE t_material_freezers; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_freezers TO readaccess;

