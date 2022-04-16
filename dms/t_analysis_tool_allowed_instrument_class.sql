--
-- Name: t_analysis_tool_allowed_instrument_class; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_tool_allowed_instrument_class (
    analysis_tool_id integer NOT NULL,
    instrument_class public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_analysis_tool_allowed_instrument_class OWNER TO d3l243;

--
-- Name: TABLE t_analysis_tool_allowed_instrument_class; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_tool_allowed_instrument_class TO readaccess;

