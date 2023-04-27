--
CREATE OR REPLACE PROCEDURE public.backup_storage_state
(
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies current contents of storage and
**      instrument tables into their backup tables
**
**  Return values: 0: failure, otherwise, experiment ID
**
**  Auth:   grk
**  Date:   04/18/2002
**          04/07/2006 grk - Got rid of CDBurn stuff
**          05/01/2009 mem - Updated description field in T_Storage_Path and T_Storage_Path_Bkup to be named SP_description
**          08/30/2010 mem - Now copying IN_Created
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Clear t_storage_path_bkup
    ---------------------------------------------------

    DELETE FROM t_storage_path_bkup
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Populate t_storage_path_bkup
    ---------------------------------------------------

    INSERT INTO t_storage_path_bkup
       (storage_path_id, storage_path, vol_name_client,
       vol_name_server, storage_path_function, instrument,
       storage_path_code, description)
    SELECT storage_path_id, storage_path, vol_name_client,
       vol_name_server, storage_path_function, instrument,
       storage_path_code, description
    FROM t_storage_path

    ---------------------------------------------------
    -- Clear t_instrument_name_bkup
    ---------------------------------------------------

    DELETE FROM t_instrument_name_bkup

    ---------------------------------------------------
    -- Populate t_instrument_name_bkup
    ---------------------------------------------------

    INSERT INTO t_instrument_name_bkup
       (instrument, instrument_id, instrument_class, IN_source_path_ID,
       storage_path_id, capture_method,
       room_number,
       description,
       created)
    SELECT instrument,
           instrument_id,
           instrument_class,
           source_path_id,
           storage_path_id,
           capture_method,
           room_number,
           description,
           created
    FROM t_instrument_name;

END
$$;

COMMENT ON PROCEDURE public.backup_storage_state IS 'BackUpStorageState';
