--
-- Name: t_seq_local_symbols_list; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_seq_local_symbols_list (
    local_symbol_id smallint NOT NULL,
    local_symbol character(1) NOT NULL,
    local_symbol_comment public.citext
);


ALTER TABLE public.t_seq_local_symbols_list OWNER TO d3l243;

--
-- Name: TABLE t_seq_local_symbols_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_seq_local_symbols_list TO readaccess;

