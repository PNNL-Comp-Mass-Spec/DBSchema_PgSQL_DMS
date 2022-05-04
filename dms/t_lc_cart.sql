--
-- Name: t_lc_cart; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart (
    cart_id integer NOT NULL,
    cart_name public.citext NOT NULL,
    cart_state_id integer DEFAULT 2 NOT NULL,
    cart_description public.citext,
    created timestamp without time zone
);


ALTER TABLE public.t_lc_cart OWNER TO d3l243;

--
-- Name: t_lc_cart_cart_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_lc_cart ALTER COLUMN cart_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_lc_cart_cart_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_lc_cart ix_t_lc_cart_unique_cart_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart
    ADD CONSTRAINT ix_t_lc_cart_unique_cart_name UNIQUE (cart_name);

--
-- Name: t_lc_cart pk_t_lc_cart; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart
    ADD CONSTRAINT pk_t_lc_cart PRIMARY KEY (cart_id);

--
-- Name: t_lc_cart fk_t_lc_cart_t_lc_cart_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart
    ADD CONSTRAINT fk_t_lc_cart_t_lc_cart_state FOREIGN KEY (cart_state_id) REFERENCES public.t_lc_cart_state_name(cart_state_id);

--
-- Name: TABLE t_lc_cart; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart TO readaccess;

