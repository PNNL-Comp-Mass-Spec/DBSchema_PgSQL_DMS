--
-- Name: t_lc_cart_config_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart_config_history (
    entry_id integer NOT NULL,
    cart public.citext NOT NULL,
    date_of_change timestamp without time zone,
    description public.citext,
    note public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext NOT NULL
);


ALTER TABLE public.t_lc_cart_config_history OWNER TO d3l243;

--
-- Name: t_lc_cart_config_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_lc_cart_config_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_lc_cart_config_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_lc_cart_config_history pk_t_lc_cart_config_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart_config_history
    ADD CONSTRAINT pk_t_lc_cart_config_history PRIMARY KEY (entry_id);

--
-- Name: t_lc_cart_config_history fk_t_lc_cart_config_history_t_lc_cart; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart_config_history
    ADD CONSTRAINT fk_t_lc_cart_config_history_t_lc_cart FOREIGN KEY (cart) REFERENCES public.t_lc_cart(cart_name);

--
-- Name: TABLE t_lc_cart_config_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart_config_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_lc_cart_config_history TO writeaccess;

