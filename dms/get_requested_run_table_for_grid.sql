--
-- Name: get_requested_run_table_for_grid(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_run_table_for_grid(_itemlist text) RETURNS TABLE(request integer, name public.citext, status public.citext, batchid integer, instrument public.citext, separation_type public.citext, experiment public.citext, cart public.citext, "column" smallint, block integer, run_order integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the info for the requested run IDs in itemList
**
**  Auth:   grk
**  Date:   01/13/2013
**          01/13/2013 grk - Initial release
**          03/14/2013 grk - Removed "Active" status filter
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          10/25/2022 mem - Ported to PostgreSQL
**          03/28/2023 mem - Update table aliases
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT RR.request_id AS Request,
           RR.request_name AS Name,
           RR.state_name AS Status,
           RR.batch_id AS BatchID,
           RR.instrument_group AS Instrument,
           RR.separation_group AS Separation_Type,
           E.experiment AS Experiment,
           LCCart.cart_name AS Cart,
           RR.cart_column AS "Column",
           RR.Block AS Block,
           RR.run_order AS Run_Order
    FROM t_requested_run RR
         INNER JOIN t_lc_cart LCCart
           ON RR.cart_id = LCCart.cart_id
         INNER JOIN t_requested_run_batches RRB
           ON RR.batch_id = RRB.batch_id
         INNER JOIN t_experiments E
           ON RR.exp_id = E.exp_id
         INNER JOIN ( SELECT Value FROM public.parse_delimited_integer_list(_itemList)) RequestQ
           ON RR.request_id = RequestQ.Value;

END
$$;


ALTER FUNCTION public.get_requested_run_table_for_grid(_itemlist text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_run_table_for_grid(_itemlist text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_run_table_for_grid(_itemlist text) IS 'GetRequestedRunsForGrid';

