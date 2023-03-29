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
**          01/13/2013 grk - initial release
**          03/14/2013 grk - removed "Active" status filter
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          10/25/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT TRR.request_id AS Request,
           TRR.request_name AS Name,
           TRR.state_name AS Status,
           TRR.batch_id AS BatchID,
           TRR.instrument_group AS Instrument,
           TRR.separation_group AS Separation_Type,
           TEX.experiment AS Experiment,
           t_lc_cart.cart_name AS Cart,
           TRR.cart_column AS "Column",
           TRR.Block AS Block,
           TRR.run_order AS Run_Order
    FROM t_requested_run TRR
         INNER JOIN t_lc_cart
           ON TRR.cart_id = t_lc_cart.cart_id
         INNER JOIN t_requested_run_batches TRB
           ON TRR.batch_id = TRB.batch_id
         INNER JOIN t_experiments TEX
           ON TRR.exp_id = TEX.exp_id
         INNER JOIN ( SELECT Value FROM public.parse_delimited_integer_list(_itemList)) RequestQ
           ON TRR.request_id = RequestQ.Value;

END
$$;


ALTER FUNCTION public.get_requested_run_table_for_grid(_itemlist text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_run_table_for_grid(_itemlist text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_run_table_for_grid(_itemlist text) IS 'GetRequestedRunsForGrid';

