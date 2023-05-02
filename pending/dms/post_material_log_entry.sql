--
CREATE OR REPLACE PROCEDURE public.post_material_log_entry
(
    _type text,
    _item text,
    _initialState text,
    _finalState text,
    _callingUser text = '',
    _comment text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new entry to T_Material_Log
**
**  Auth:   grk
**  Date:   03/20/2008
**          03/25/2008 mem - Now validating that _callingUser is not blank
**          03/26/2008 grk - added handling for comment
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Make sure _callingUser is not blank
    ---------------------------------------------------

    _callingUser := Coalesce(_callingUser, '');
    If char_length(_callingUser) = '' Then
        _callingUser := session_user;
    End If;

    ---------------------------------------------------
    -- Weed out useless postings
    -- (example: movement where origin same as destination)
    ---------------------------------------------------

    If _initialState = _finalState Then
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
        username,
        comment
    ) VALUES (
        _type,
        _item,
        _initialState,
        _finalState,
        _callingUser,
        _comment
    );
END
$$;

COMMENT ON PROCEDURE public.post_material_log_entry IS 'PostMaterialLogEntry';
