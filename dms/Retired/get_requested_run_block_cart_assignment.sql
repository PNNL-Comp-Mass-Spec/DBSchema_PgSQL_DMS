--
-- Name: get_requested_run_block_cart_assignment(integer, integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_run_block_cart_assignment(_batchid integer, _block integer, _mode text DEFAULT 'cart'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns cart assignment, or column assignment
**      for given requested run batch and block
**
**  Return value: cart or column (or '(mixed)')
**
**  Arguments:
**    _mode   'cart' or 'col'
**
**  Auth:   grk
**  Date:   02/12/2010
**          06/22/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cart text;
    _column text;
BEGIN
    _cart := '';
    _column := '';

    If _batchID IS NULL OR _block IS NULL THEN
        Return '';
    End If;

    SELECT string_agg(DistinctQ.Cart, '; ' ORDER BY DistinctQ.Cart),
           string_agg(Coalesce(DistinctQ.Col::text, '0'), '; ' ORDER BY DistinctQ.Col)
    INTO _cart, _column
    FROM ( SELECT DISTINCT t_lc_cart.cart_name AS Cart,
                           t_requested_run.cart_column AS Col
           FROM t_requested_run
                INNER JOIN t_lc_cart
                  ON t_requested_run.cart_id = t_lc_cart.cart_id
           WHERE t_requested_run.batch_id = _batchID AND
                 t_requested_run.block = _block ) AS DistinctQ;

    If Trim(Lower(_mode)) = 'cart' Then
        If Position ('; ' in _cart) > 0 Then
            Return '(mixed)';
        Else
            Return Coalesce(_cart, '');
        End If;
    Else
        If Position ('; ' in _column) > 0 Then
            Return '(mixed)';
        Else
            Return Coalesce(_column, '');
        End If;
    End If;
END
$$;


ALTER FUNCTION public.get_requested_run_block_cart_assignment(_batchid integer, _block integer, _mode text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_run_block_cart_assignment(_batchid integer, _block integer, _mode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_run_block_cart_assignment(_batchid integer, _block integer, _mode text) IS 'GetRequestedRunBlockCartAssignment';

