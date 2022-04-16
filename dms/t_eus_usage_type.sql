--
-- Name: t_eus_usage_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_usage_type (
    eus_usage_type_id smallint NOT NULL,
    eus_usage_type public.citext NOT NULL,
    description public.citext,
    enabled smallint NOT NULL,
    enabled_campaign smallint NOT NULL,
    enabled_prep_request smallint NOT NULL
);


ALTER TABLE public.t_eus_usage_type OWNER TO d3l243;

--
-- Name: TABLE t_eus_usage_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_usage_type TO readaccess;

