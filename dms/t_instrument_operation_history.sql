--
-- Name: t_instrument_operation_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_operation_history (
    entry_id integer NOT NULL,
    instrument public.citext NOT NULL,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext NOT NULL,
    note public.citext NOT NULL
);


ALTER TABLE public.t_instrument_operation_history OWNER TO d3l243;

--
-- Name: TABLE t_instrument_operation_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_operation_history TO readaccess;

