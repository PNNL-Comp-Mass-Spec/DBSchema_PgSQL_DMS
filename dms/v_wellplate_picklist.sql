--
-- Name: v_wellplate_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_wellplate_picklist AS
 SELECT ((((((w.wellplate)::text || (',  '::public.citext)::text))::public.citext)::text || (COALESCE(
        CASE
            WHEN (char_length((w.description)::text) > 48) THEN ("substring"((w.description)::text, 1, 48))::public.citext
            ELSE w.description
        END, ''::public.citext))::text))::public.citext AS val,
    w.wellplate AS ex
   FROM public.t_wellplates w;


ALTER VIEW public.v_wellplate_picklist OWNER TO d3l243;

--
-- Name: TABLE v_wellplate_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_wellplate_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_wellplate_picklist TO writeaccess;

