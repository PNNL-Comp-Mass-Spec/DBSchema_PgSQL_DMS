--
-- Name: auto_update_settings_file_to_centroid(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.auto_update_settings_file_to_centroid(_settingsfile text, _toolname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Automatically change the settings file to a version that uses MSConvert to centroid the data
**      This is useful for QExactive datasets, since DeconMSn seems to do more harm than good with QExactive data
**      Also useful for Orbitrap datasets with profile-mode MS/MS spectra
**
**  Return value: delimited list
**
**  Auth:   mem
**  Date:   04/09/2013
**          01/11/2015 mem - Updated MSGF+ settings files to use DeconMSn_Centroid versions
**          03/30/2015 mem - Added parameter _toolName
**                         - Now retrieving MSGF+ auto-centroid values from column MSGFPlus_AutoCentroid
**                         - Renamed the procedure from AutoUpdateQExactiveSettingsFile
**          06/17/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _newSettingsFile text := '';
BEGIN
    -- First look for a match in t_settings_files

    SELECT msgfplus_auto_centroid
    INTO _newSettingsFile
    FROM t_settings_files
    WHERE file_name = _settingsFile AND
          analysis_tool = _toolName;

    If Coalesce(_newSettingsFile, '') = '' And _toolName Like 'Sequest%' Then
        -- Sequest Settings Files
        If _settingsFile = 'FinniganDefSettings_DeconMSn.xml' Then
            _newSettingsFile := 'FinniganDefSettings_MSConvert.xml';
        End If;

        If _settingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk.xml' Then
            _newSettingsFile := 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk.xml';
        End If;

        If _settingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk_4plexITRAQ.xml' Then
            _newSettingsFile := 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ.xml';
        End If;

        If _settingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk_4plexITRAQ_phospho.xml' Then
            _newSettingsFile := 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ_phospho.xml';
        End If;
    End If;

    If Coalesce(_newSettingsFile, '') <> '' Then
        _settingsFile := _newSettingsFile;
    End If;

    RETURN _settingsFile;

END
$$;


ALTER FUNCTION public.auto_update_settings_file_to_centroid(_settingsfile text, _toolname text) OWNER TO d3l243;

--
-- Name: FUNCTION auto_update_settings_file_to_centroid(_settingsfile text, _toolname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.auto_update_settings_file_to_centroid(_settingsfile text, _toolname text) IS 'AutoUpdateSettingsFileToCentroid';

