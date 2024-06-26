--
-- Name: get_experiment_plex_members_for_entry(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_experiment_plex_members_for_entry(_plexexperimentid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of experiment plex members for a given experiment plex
**
**  Arguments:
**     _plexExperimentID    Plex experiment ID
**
**  Returns:
**      List delimited with line feeds and vertical bars
**
**  Auth:   mem
**  Date:   11/09/2018 mem
**          11/19/2018 mem - Update column name
**          06/21/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(plex_exp_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _headerRow text;
    _list text;
    _result text;
    _missingTagCount int := 0;
    _channelCount int := 0;
BEGIN
    SELECT SUM(CASE WHEN char_length(Coalesce(ReporterIons.tag_name, '')) = 0 THEN 1 ELSE 0 END),
           COUNT(plex_exp_id)
    INTO _missingTagCount, _channelCount
    FROM t_experiment_plex_members PlexMembers
        INNER JOIN t_experiments ChannelExperiment
            ON PlexMembers.exp_id = ChannelExperiment.exp_id
        INNER JOIN t_experiments E
            ON PlexMembers.plex_exp_id = E.exp_id
        LEFT OUTER JOIN t_sample_labelling_reporter_ions ReporterIons
            ON PlexMembers.channel = ReporterIons.channel AND
                E.labelling = ReporterIons.label
    WHERE PlexMembers.plex_exp_id = _plexExperimentID;

    SELECT string_agg(LookupQ.PlexMemberInfo, chr(10) ORDER BY LookupQ.channel)
    INTO _list
    FROM (SELECT PlexMembers.channel,
                 format('%s, %s, %s, %s',
                         Coalesce(ReporterIons.tag_name, PlexMembers.channel::text),
                         PlexMembers.exp_id,
                         ChannelType.channel_type_name,
                         Coalesce(PlexMembers.comment, '')) AS PlexMemberInfo
          FROM t_experiment_plex_members PlexMembers
               INNER JOIN t_experiments ChannelExperiment
                 ON PlexMembers.exp_id = ChannelExperiment.exp_id
               INNER JOIN t_experiment_plex_channel_type_name ChannelType
                 ON PlexMembers.channel_type_id = ChannelType.channel_type_id
               INNER JOIN t_experiments E
                 ON PlexMembers.plex_exp_id = E.exp_id
               LEFT OUTER JOIN t_sample_labelling_reporter_ions ReporterIons
                 ON PlexMembers.channel = ReporterIons.channel AND
                    E.labelling = ReporterIons.label
          WHERE PlexMembers.plex_exp_id = _plexExperimentID) LookupQ;

    If _missingTagCount > 0 And _missingTagCount = _channelCount Then
        _headerRow := 'Channel, Exp_ID, Channel Type, Comment';
    Else
        _headerRow := 'Tag, Exp_ID, Channel Type, Comment';
    End If;

    If Coalesce(_list, '') = ''  Then
        _result := _headerRow;
    Else
        _result := format('%s%s%s', _headerRow, chr(10), _list);
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_experiment_plex_members_for_entry(_plexexperimentid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_experiment_plex_members_for_entry(_plexexperimentid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_experiment_plex_members_for_entry(_plexexperimentid integer) IS 'GetExperimentPlexMembersForEntry';

