--
-- Name: t_internal_std_components; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_std_components (
    internal_std_component_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    monoisotopic_mass double precision NOT NULL,
    charge_minimum integer,
    charge_maximum integer,
    charge_highest_abu integer,
    expected_ganet double precision
);


ALTER TABLE public.t_internal_std_components OWNER TO d3l243;

--
-- Name: TABLE t_internal_std_components; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_std_components TO readaccess;

