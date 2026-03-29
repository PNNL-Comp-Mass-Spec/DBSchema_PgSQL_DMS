--
-- Name: update_dms_nom_stats_xml(integer, boolean, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_dms_nom_stats_xml(IN _datasetid integer, IN _deletefromtableonsuccess boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Call public.update_dataset_nom_stats_xml() for the specified DatasetID
**
**      Procedure public.update_dataset_nom_stats_xml uses data in cap.t_dataset_nom_stats_xml
**      to populate t_dataset_nom_stats
**
**  Arguments:
**    _datasetID                    Dataset ID
**    _deleteFromTableOnSuccess     When true, delete from cap.t_dataset_nom_stats_xml if successfully stored in the dataset tables
**    _message                      Status message
**    _returnCode                   Return code; will be 'U5360' if this dataset is a duplicate to another dataset (based on T_Dataset_Files)
**    _infoOnly                     When true, preview updates
**
**  Auth:   mem
**  Date:   03/28/2026 mem - Initial Version
**
*****************************************************/
DECLARE
    _nomStatsXML xml;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _deleteFromTableOnSuccess := Coalesce(_deleteFromTableOnSuccess, true);
    _infoOnly                 := Coalesce(_infoOnly, false);

    SELECT nom_stats_xml
    INTO _nomStatsXML
    FROM cap.t_dataset_nom_stats_xml
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        RAISE WARNING 'Dataset ID % not found in cap.t_dataset_nom_stats_xml', _datasetID;
        RETURN;
    End If;

    If _nomStatsXML Is Null Then
        RAISE WARNING 'NOM stats XML is null for Dataset ID % in cap.t_dataset_nom_stats_xml', _datasetID;
        RETURN;
    End If;

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Call public.update_dataset_nom_stats_xml for Dataset ID %', _datasetID;
    End If;

    CALL public.update_dataset_nom_stats_xml (
                    _datasetID,
                    _nomStatsXML,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _infoOnly   => _infoOnly);

    If _returnCode = '' And Not _infoOnly And _deleteFromTableOnSuccess Then
        DELETE FROM cap.t_dataset_nom_stats_xml
        WHERE dataset_id = _datasetID;
    End If;
END
$$;


ALTER PROCEDURE cap.update_dms_nom_stats_xml(IN _datasetid integer, IN _deletefromtableonsuccess boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

