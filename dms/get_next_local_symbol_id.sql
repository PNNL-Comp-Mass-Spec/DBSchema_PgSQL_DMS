--
-- Name: get_next_local_symbol_id(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_next_local_symbol_id(_paramfileid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get next available local symbol ID for a given parameter file ID
**
**  Arguments:
**    _paramFileID  Parameter file ID
**
**  Returns:
**      Next available local symbol ID (as an integer)
**
**  Auth:   kja
**  Date:   08/10/2004
**          10/01/2009 mem - Updated to jump from ID 3 to ID 9 for SEQUEST param files
**          08/03/2017 mem - Add Set NoCount On
**          01/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _localSymbolID int;
    _nextSymbolID int := 0;
    _paramFileTypeID int := 0;
BEGIN
    -- Determine the param file type for this param file ID
    SELECT param_file_type_id
    INTO _paramFileTypeID
    FROM t_param_files
    WHERE param_file_id = _paramFileID;

    -- Determine the highest used Local_Symbol_ID for the mods for this parameter file
    SELECT MAX(local_symbol_id)
    INTO _localSymbolID
    FROM t_param_file_mass_mods
    WHERE param_file_id = _paramFileID;

    If Not FOUND Or _localSymbolID Is Null Then
        _localSymbolID := 0;
    End If;

    If Coalesce(_paramFileTypeID, 0) = 1000 Then
        -- This is a SEQUEST parameter file
        -- The order of symbols needs to be
        --   * # @ ^ ~

        -- To do this, we need to handle cases when _localSymbolID is 3, 10, or 11
        --
        -- Jump from symbol 3 to symbol 10
        -- and from symbol 10 to symbol 11
        -- and from symbol 11 to symbol 4

        If _localSymbolID = 3 Then
            _nextSymbolID := 10;        -- Max symbol is @, next needs to be ^;
        End If;

        If _localSymbolID = 10 Then
            _nextSymbolID := 11;        -- Max symbol is ^, next needs to be ~;
        End If;

        If _localSymbolID = 11 Then
            -- Max symbol is ~, we now need to loop back and start using 4, 5, 6, and 7
            SELECT MAX(local_symbol_id)
            INTO _localSymbolID
            FROM t_param_file_mass_mods
            WHERE param_file_id = _paramFileID AND local_symbol_id < 10;

            If Not FOUND Then
                _localSymbolID := 0;
            End If;

            _nextSymbolID := _localSymbolID + 1;
        End If;

        -- See if _nextSymbolID is still 0

        -- If it is still 0, none of the special cases was encountered above,
        -- so just assign _nextSymbolID to be one more than _localSymbolID

        If Coalesce(_nextSymbolID, 0) = 0 Then
            _nextSymbolID := _localSymbolID + 1;
        End If;

    Else
        -- Assign _nextSymbolID to be one more than _localSymbolID
        _nextSymbolID := _localSymbolID + 1;
    End If;

    RETURN _nextSymbolID;
END
$$;


ALTER FUNCTION public.get_next_local_symbol_id(_paramfileid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_next_local_symbol_id(_paramfileid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_next_local_symbol_id(_paramfileid integer) IS 'GetNextLocalSymbolID';

