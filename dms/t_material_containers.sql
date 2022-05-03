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
    researcher public.citext,
    sort_key integer GENERATED ALWAYS AS (
CASE
    WHEN (container OPERATOR(public.=) 'Staging'::public.citext) THEN 2147483645
    WHEN (container OPERATOR(public.=) 'Met_Staging'::public.citext) THEN 2147483644
    WHEN (container OPERATOR(public.~~) '%Staging%'::public.citext) THEN (2147483500 + char_length((container)::text))
    WHEN (container OPERATOR(public.=) 'na'::public.citext) THEN 2147483500
    WHEN (container OPERATOR(public.~) similar_to_escape('MC-[0-9]%'::text)) THEN ("substring"((container)::text, 4, 1000))::integer
    WHEN (container OPERATOR(public.~~) 'Bin%'::public.citext) THEN char_length((container)::text)
    ELSE (ascii("substring"((container)::text, 1, 1)) * 10000000)
END) STORED
);


ALTER TABLE public.t_material_containers OWNER TO d3l243;

--
-- Name: t_material_containers_container_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_material_containers ALTER COLUMN container_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_material_containers_container_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_material_containers pk_t_material_containers; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_containers
    ADD CONSTRAINT pk_t_material_containers PRIMARY KEY (container_id);

--
-- Name: TABLE t_material_containers; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_containers TO readaccess;

