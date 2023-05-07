--
-- Name: duplicatemanagerparameters(integer, integer, integer, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.duplicatemanagerparameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget integer DEFAULT 0, _infoonly integer DEFAULT 0) RETURNS TABLE(type_id integer, value public.citext, mgr_id integer, comment public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Duplicates the parameters for a given manager
**      to create new parameters for a new manager
**
**  Example usage:
**    select * from DuplicateManagerParameter(157, 172)
**
**  Arguments:
**    _mergeSourceWithTarget    When 0, then the target manager cannot have any parameters; if 1, then will add missing parameters to the target manager
**
**  Auth:   mem
**  Date:   10/10/2014 mem - Initial release
**          02/01/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text = '';
    _returnCode text = '';
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, 1);
    _mergeSourceWithTarget := Coalesce(_mergeSourceWithTarget, 0);

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
        SELECT 0 as type_id,
               'Warning'::citext as value,
               0,
               _message::citext as comment;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the source and target managers exist
    ---------------------------------------------------

    If _returnCode = '' And Not Exists (Select * From mc.t_mgrs Where mgr_id = _sourceMgrID) Then
        _message := '_sourceMgrID ' || _sourceMgrID || ' not found in mc.t_mgrs; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5203';
    End If;

    If _returnCode = '' And Not Exists (Select * From mc.t_mgrs Where mgr_id = _targetMgrID) Then
        _message := '_targetMgrID ' || _targetMgrID || ' not found in mc.t_mgrs; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5204';
    End If;

    If _returnCode = '' And _mergeSourceWithTarget = 0 Then
        -- Make sure the target manager does not have any parameters
        --
        If Exists (SELECT * FROM mc.t_param_value WHERE mgr_id = _targetMgrID) Then
            _message := '_targetMgrID ' + _targetMgrID + ' has existing parameters in mc.t_param_value; aborting since _mergeSourceWithTarget = 0';
            _returnCode := 'U5205';
        End If;
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 0 as type_id,
               'Warning'::citext as value,
               0 as mgr_id,
               _message::citext as comment;
        RETURN;
    End If;

    If _infoOnly <> 0 Then
            RETURN QUERY
            SELECT Source.type_id,
                   Source.value,
                   _targetMgrID AS mgr_id,
                   Source.comment
            FROM mc.t_param_value AS Source
                 LEFT OUTER JOIN ( SELECT PV.type_id
                                   FROM mc.t_param_value PV
                                   WHERE PV.mgr_id = _targetMgrID ) AS ExistingParams
                   ON Source.type_id = ExistingParams.type_id
            WHERE Source.mgr_id = _sourceMgrID AND
                  ExistingParams.type_id IS NULL;
            Return;
    End If;

    INSERT INTO mc.t_param_value (type_id, value, mgr_id, comment)
    SELECT Source.type_id,
           Source.value,
           _targetMgrID AS mgr_id,
           Source.comment
    FROM mc.t_param_value AS Source
         LEFT OUTER JOIN ( SELECT PV.type_id
                           FROM mc.t_param_value PV
                           WHERE PV.mgr_id = _targetMgrID ) AS ExistingParams
           ON Source.type_id = ExistingParams.type_id
    WHERE Source.mgr_id = _sourceMgrID AND
          ExistingParams.type_id IS NULL;

    RETURN QUERY
        SELECT PV.type_id, PV.value, PV.mgr_id, PV.comment
        FROM mc.t_param_value PV
        WHERE PV.mgr_id = _targetMgrID;


EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error duplicating manager parameters: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    RETURN QUERY
    SELECT 0 as type_id,
           'Error'::citext as value,
           0 as mgr_id,
           _message::citext as comment;

END
$$;


ALTER FUNCTION mc.duplicatemanagerparameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget integer, _infoonly integer) OWNER TO d3l243;

--
-- Name: FUNCTION duplicatemanagerparameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget integer, _infoonly integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.duplicatemanagerparameters(_sourcemgrid integer, _targetmgrid integer, _mergesourcewithtarget integer, _infoonly integer) IS 'DuplicateManagerParameters';

