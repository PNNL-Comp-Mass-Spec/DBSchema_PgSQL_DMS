--
-- Name: t_eus_site_status; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_site_status (
    eus_site_status_id smallint NOT NULL,
    eus_site_status public.citext NOT NULL,
    short_name public.citext
);


ALTER TABLE public.t_eus_site_status OWNER TO d3l243;

--
-- Name: TABLE t_eus_site_status; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_site_status TO readaccess;

