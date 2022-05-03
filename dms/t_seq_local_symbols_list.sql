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
-- Name: t_seq_local_symbols_list_local_symbol_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_seq_local_symbols_list ALTER COLUMN local_symbol_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_seq_local_symbols_list_local_symbol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_seq_local_symbols_list pk_t_seq_local_symbols_list; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_seq_local_symbols_list
    ADD CONSTRAINT pk_t_seq_local_symbols_list PRIMARY KEY (local_symbol_id);

--
-- Name: TABLE t_seq_local_symbols_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_seq_local_symbols_list TO readaccess;

