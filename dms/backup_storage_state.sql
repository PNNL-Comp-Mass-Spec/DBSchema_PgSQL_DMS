--
-- Name: backup_storage_state(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.backup_storage_state(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Copy current contents of storage and instrument tables into their backup tables
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   04/18/2002
**          04/07/2006 grk - Got rid of CDBurn stuff
**          05/01/2009 mem - Updated description field in T_Storage_Path and T_Storage_Path_Bkup to be named SP_description
**          08/30/2010 mem - Now copying column created
**          05/07/2023 mem - Ported to PostgreSQL
**          07/23/2024 mem - Also copy data from columns instrument_group and status
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Clear t_storage_path_bkup
    ---------------------------------------------------

    DELETE FROM t_storage_path_bkup;

    ---------------------------------------------------
    -- Populate t_storage_path_bkup
    ---------------------------------------------------

    INSERT INTO t_storage_path_bkup (
        storage_path_id,
        storage_path,
        vol_name_client,
        vol_name_server,
        storage_path_function,
        instrument,
        storage_path_code,
        description
    )
    SELECT storage_path_id,
           storage_path,
           vol_name_client,
           vol_name_server,
           storage_path_function,
           instrument,
           storage_path_code,
           description
    FROM t_storage_path;

    ---------------------------------------------------
    -- Clear t_instrument_name_bkup
    ---------------------------------------------------

    DELETE FROM t_instrument_name_bkup;

    ---------------------------------------------------
    -- Populate t_instrument_name_bkup
    ---------------------------------------------------

    INSERT INTO t_instrument_name_bkup (
        instrument_id,
        instrument,
        instrument_class,
        instrument_group,
        source_path_id,
        storage_path_id,
        capture_method,
        status,
        room_number,
        description,
        created
    )
    SELECT instrument_id,
           instrument,
           instrument_class,
           instrument_group,
           source_path_id,
           storage_path_id,
           capture_method,
           status,
           room_number,
           description,
           created
    FROM t_instrument_name;

END
$$;


ALTER PROCEDURE public.backup_storage_state(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE backup_storage_state(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.backup_storage_state(INOUT _message text, INOUT _returncode text) IS 'BackUpStorageState';

