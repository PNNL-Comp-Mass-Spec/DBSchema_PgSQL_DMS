--
CREATE OR REPLACE FUNCTION public.get_next_local_symbol_id
(
    _paramFileID int
)
RETURNS text
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Gets next available LocalSymbolID for a given paramFileID
**
**  Return values: next available local symbol id
**
**  Auth:   kja
**  Date:   08/10/2004
**          10/01/2009 mem - Updated to jump from ID 3 to ID 9 for Sequest param files
**          08/03/2017 mem - Add Set NoCount On
**          12/15/2023 mem - Ported to PostgreSQL
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
    WHERE (param_file_id = _paramFileID)

    -- Determine the highest used Local_Symbol_ID for the mods for this parameter file
    SELECT MAX(local_symbol_id)
    INTO _localSymbolID
    FROM t_param_file_mass_mods
    WHERE (param_file_id = _paramFileID)

    If Not FOUND Or _localSymbolID is null Then
        _localSymbolID := 0;
    End If;

    If _paramFileTypeID = 1000 Then
        -- This is a Sequest parameter file
        -- The order of symbols needs to be
        --   * # @ ^ ~

        -- To do this, we need to handle cases when _localSymbolID is 3, 10, or 11
        --
        -- Jump from symbol 3 to symbol 10
        -- and from symbol 10 to symbol 11
        -- and from symbol 11 to symbol 4

        If _localSymbolID = 3 Then
            _nextSymbolID := 10        -- Max symbol is @, next needs to be ^;
        End If;

        If _localSymbolID = 10 Then
            _nextSymbolID := 11        -- Max symbol is ^, next needs to be ~;
        End If;

        If _localSymbolID = 11 Then
            -- Max symbol is ~, we now need to loop back and start using 4, 5, 6, and 7
            SELECT MAX(local_symbol_id)
            INTO _localSymbolID
            FROM t_param_file_mass_mods
            WHERE (param_file_id = _paramFileID) AND local_symbol_id < 10;

            If Not FOUND Then
                _localSymbolID := 0;
            End If;

            _nextSymbolID := _localSymbolID + 1;
        End If;

        -- See if _nextSymbolID is still 0

        -- If it is still 0, none of the special cases was encountered above,
        -- so just assign _nextSymbolID to be one more than _localSymbolID

        If _nextSymbolID = 0 Then
            _nextSymbolID := _localSymbolID + 1;
        End If;

    Else
        -- Assign _nextSymbolID to be one more than _localSymbolID
        _nextSymbolID := _localSymbolID + 1;
    End If;

    RETURN _nextSymbolID;
END
$$;

COMMENT ON FUNCTION public.get_next_local_symbol_id IS 'GetNextLocalSymbolID';
