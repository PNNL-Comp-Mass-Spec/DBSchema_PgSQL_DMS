--
-- Name: backup_storage_state(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.backup_storage_state(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
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
**          05/07/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Clear t_storage_path_bkup
    ---------------------------------------------------

    DELETE FROM t_storage_path_bkup;

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
    FROM t_storage_path;

    ---------------------------------------------------
    -- Clear t_instrument_name_bkup
    ---------------------------------------------------

    DELETE FROM t_instrument_name_bkup;

    ---------------------------------------------------
    -- Populate t_instrument_name_bkup
    ---------------------------------------------------

    INSERT INTO t_instrument_name_bkup
       (instrument, instrument_id, instrument_class, source_path_id,
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


ALTER PROCEDURE public.backup_storage_state(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE backup_storage_state(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.backup_storage_state(INOUT _message text, INOUT _returncode text) IS 'BackUpStorageState';

