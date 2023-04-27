--
CREATE OR REPLACE PROCEDURE dpkg.post_log_entry
(
    _type text,
    _message text,
    _postedBy text= 'na',
    _duplicateEntryHoldoffHours int = 0,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Calls PostLogEntry to add a new entry to
**        the main log table
**
**  Arguments:
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
**
**  Auth:   mem
**  Date:   04/17/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _returnValue int := 0;
BEGIN
    Call _returnValue => post_log_entry _type, _message, _postedBy, _duplicateEntryHoldoffHours, _callingUser

    return _returnValue

END
$$;

COMMENT ON PROCEDURE dpkg.post_log_entry IS 'post_log_entry';
