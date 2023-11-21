--
-- Name: post_material_log_entry(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.post_material_log_entry(IN _type text, IN _item text, IN _initialstate text, IN _finalstate text, IN _callinguser text, IN _comment text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new entry to T_Material_Log for an experiment, reference compound, biomaterial item, or material container
**
**  Arguments:
**    _type             Type of action: 'Experiment Move', 'Reference Compound Move', 'Biomaterial Move', 'Container Creation', or 'Container Move'
**    _item             Item name
**    _initialState     Old container name (or, for material containers, old location)
**    _finalState       New container name (or, for material containers, new location)
**    _comment          Log comment
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   03/20/2008
**          03/25/2008 mem - Now validating that _callingUser is not blank
**          03/26/2008 grk - Added handling for comment
**          11/20/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN

    ---------------------------------------------------
    -- Make sure _callingUser is not blank
    ---------------------------------------------------

    _callingUser := Trim(Coalesce(_callingUser, ''));

    If char_length(_callingUser) = 0 Then
        _callingUser := session_user;
    End If;

    ---------------------------------------------------
    -- Weed out useless postings
    -- (example: movement where origin same as destination)
    ---------------------------------------------------

    If _initialState::citext = _finalState::citext Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action
    ---------------------------------------------------

    INSERT INTO t_material_log (
        type,
        item,
        initial_state,
        final_state,
        comment,
        username
    ) VALUES (
        _type,
        _item,
        _initialState,
        _finalState,
        _comment,
        _callingUser
    );
END
$$;


ALTER PROCEDURE public.post_material_log_entry(IN _type text, IN _item text, IN _initialstate text, IN _finalstate text, IN _callinguser text, IN _comment text) OWNER TO d3l243;

--
-- Name: PROCEDURE post_material_log_entry(IN _type text, IN _item text, IN _initialstate text, IN _finalstate text, IN _callinguser text, IN _comment text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.post_material_log_entry(IN _type text, IN _item text, IN _initialstate text, IN _finalstate text, IN _callinguser text, IN _comment text) IS 'PostMaterialLogEntry';

