--
CREATE OR REPLACE PROCEDURE public.add_update_lc_cart_config_history
(
    _id int,
    _cart text,
    _dateOfChange text,
    _postedBy text,
    _description text,
    _note text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing cart config history entry
**
**  Arguments:
**    _id               Entry_ID in t_lc_cart_config_history
**    _cart             Cart name
**    _dateOfChange     Date for the cart config history item
**    _postedBy         Username of the person associated with the cart config history item
**    _description      General description of the task, e.g. 'Replaced rotors' or 'Replaced Syringe'
**    _note             Additional details
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/09/2011
**          03/26/2012 grk - Added _postedBy
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          11/25/2023 mem - Validate LC cart name
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _entryDate timestamp;
    _tmp int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _cart      := Trim(Coalesce(_cart, ''));
        _entryDate := public.try_cast(_dateOfChange, null, null::timestamp);
        _mode      := Trim(Lower(Coalesce(_mode, '')));

        If _entryDate Is Null Then
            _entryDate := CURRENT_TIMESTAMP;
        End If;

        If Trim(Coalesce(_postedBy, '')) = '' Then
            _postedBy := _callingUser;
        End If;

        If Not Exists (SELECT cart_id FROM t_lc_cart WHERE cart_name = _cart) Then
            RAISE EXCEPTION 'Unrecognized LC cart name: %', _cart;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry

            SELECT entry_id
            INTO _tmp
            FROM  t_lc_cart_config_history
            WHERE entry_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'Cart config history ID % not found in database for update', _id;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_lc_cart_config_history (
                cart,
                date_of_change,
                description,
                note,
                entered_by
            ) VALUES (
                 _cart,
                 _entryDate,
                _description,
                _note,
                _postedBy
            )
            RETURNING entry_id
            INTO _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_lc_cart_config_history
            SET cart = _cart,
                date_of_change = _entryDate,
                description = _description,
                note = _note,
                entered_by = _postedBy
            WHERE entry_id = _id;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Cart %s, ID %s', _exceptionMessage, _cart, _id);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;

COMMENT ON PROCEDURE public.add_update_lc_cart_config_history IS 'AddUpdateLCCartConfigHistory';
