--
-- Name: duplicate_manager_parameters(integer, integer, boolean, boolean); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.duplicate_manager_parameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget boolean DEFAULT false, _infoonly boolean DEFAULT false) RETURNS TABLE(param_type_id integer, value public.citext, mgr_id integer, comment public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Duplicates the parameters for a given manager
**      to create new parameters for a new manager
**
**  Arguments:
**    _sourceMgrID              Source manager ID
**    _targetMgrID              Target manager ID
**    _mergeSourceWithTarget    When false, the target manager cannot have any parameters; if true, will add missing parameters to the target manager
**    _infoOnly                 False to perform the update, true to preview
**
**  Example usage:
**    SELECT * FROM duplicate_manager_parameters(157, 172, _infoOnly => true)
**
**  Auth:   mem
**  Date:   10/10/2014 mem - Initial release
**          02/01/2020 mem - Ported to PostgreSQL
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _infoOnly and _mergeSourceWithTarget from integer to boolean
**          02/01/2023 mem - Use new column name in view
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text = '';
    _returnCode text = '';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _mergeSourceWithTarget := Coalesce(_mergeSourceWithTarget, false);

    If _returnCode = '' And _sourceMgrID Is Null Then
        _message := '_sourceMgrID cannot be null; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5200';
    End If;

    If _returnCode = '' And _targetMgrID Is Null Then
        _message := '_targetMgrID cannot be null; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 0 as param_type_id,
               'Warning'::citext as value,
               0,
               _message::citext as comment;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the source and target managers exist
    ---------------------------------------------------

    If _returnCode = '' And Not Exists (Select * From mc.t_mgrs M Where M.mgr_id = _sourceMgrID) Then
        _message := '_sourceMgrID ' || _sourceMgrID || ' not found in mc.t_mgrs; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5203';
    End If;

    If _returnCode = '' And Not Exists (Select * From mc.t_mgrs M Where M.mgr_id = _targetMgrID) Then
        _message := '_targetMgrID ' || _targetMgrID || ' not found in mc.t_mgrs; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5204';
    End If;

    If _returnCode = '' And Not _mergeSourceWithTarget Then
        -- Make sure the target manager does not have any parameters
        --
        If Exists (SELECT * FROM mc.t_param_value PV WHERE PV.mgr_id = _targetMgrID) Then
            _message := format('_targetMgrID %s has existing parameters in mc.t_param_value; aborting since _mergeSourceWithTarget is false', _targetMgrID);
            _returnCode := 'U5205';
        End If;
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 0 as param_type_id,
               'Warning'::citext as value,
               0 as mgr_id,
               _message::citext as comment;
        RETURN;
    End If;

    If _infoOnly Then
            RETURN QUERY
            SELECT Source.param_type_id,
                   Source.value,
                   _targetMgrID AS mgr_id,
                   Source.comment
            FROM mc.t_param_value AS Source
                 LEFT OUTER JOIN ( SELECT PV.param_type_id
                                   FROM mc.t_param_value PV
                                   WHERE PV.mgr_id = _targetMgrID ) AS ExistingParams
                   ON Source.param_type_id = ExistingParams.param_type_id
            WHERE Source.mgr_id = _sourceMgrID AND
                  ExistingParams.param_type_id IS NULL;
            Return;
    End If;

    INSERT INTO mc.t_param_value (param_type_id, value, mgr_id, comment)
    SELECT Source.param_type_id,
           Source.value,
           _targetMgrID AS mgr_id,
           Source.comment
    FROM mc.t_param_value AS Source
         LEFT OUTER JOIN ( SELECT PV.param_type_id
                           FROM mc.t_param_value PV
                           WHERE PV.mgr_id = _targetMgrID ) AS ExistingParams
           ON Source.param_type_id = ExistingParams.param_type_id
    WHERE Source.mgr_id = _sourceMgrID AND
          ExistingParams.param_type_id IS NULL;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    RETURN QUERY
        SELECT PV.param_type_id, PV.value, PV.mgr_id, PV.comment
        FROM mc.t_param_value PV
        WHERE PV.mgr_id = _targetMgrID;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    _logError => true);

    RETURN QUERY
    SELECT 0 as param_type_id,
           'Error'::citext as value,
           0 as mgr_id,
           _message::citext as comment;

END
$$;


ALTER FUNCTION mc.duplicate_manager_parameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget boolean, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION duplicate_manager_parameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget boolean, _infoonly boolean); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.duplicate_manager_parameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget boolean, _infoonly boolean) IS 'DuplicateManagerParameters';

