/*
<doc>
	<summary>
        This function return people who attended based on selected filter criteria and the first 5 dates they ever attended the selected group type
	</summary>

	<returns>
		* PersonId
		* TimeAttending
		* SundayDate
	</returns>
	<param name='GroupTypeId' datatype='int'>The Check-in Area Group Type Id (only attendance for this are will be included</param>
	<param name='StartDate' datatype='datetime'>Beginning date range filter</param>
	<param name='EndDate' datatype='datetime'>Ending date range filter</param>
	<param name='GroupIds' datatype='varchar(max)'>Optional list of group ids to limit attendance to</param>
	<param name='CampusIds' datatype='varchar(max)'>Optional list of campus ids to limit attendance to</param>
	<param name='IncludeNullCampusIds' datatype='bit'>Flag indicating if attendance not tied to campus should be included</param>
	<remarks>	
	</remarks>
	<code>
		EXEC [dbo].[spCheckin_AttendanceAnalyticsQuery_AttendeeLastAttendance] '15,16,17,18,19,20,21,22', '2015-01-01 00:00:00', '2015-12-31 23:59:59', null, 0
	</code>
</doc>
*/

ALTER PROCEDURE [dbo].[spCheckin_AttendanceAnalyticsQuery_AttendeeLastAttendance]
	  @GroupIds varchar(max) 
	, @StartDate datetime = NULL
	, @EndDate datetime = NULL
	, @CampusIds varchar(max) = NULL
	, @IncludeNullCampusIds bit = 0
	, @ScheduleIds varchar(max) = NULL

AS

BEGIN

    -- Manipulate dates to only be those dates who's SundayDate value would fall between the selected date range ( so that sunday date does not need to be used in where clause )
	SET @StartDate = COALESCE( DATEADD( day, ( 0 - DATEDIFF( day, CONVERT( datetime, '19000101', 112 ), @StartDate ) % 7 ), CONVERT( date, @StartDate ) ), '1900-01-01' )
	SET @EndDate = COALESCE( DATEADD( day, ( 0 - DATEDIFF( day, CONVERT( datetime, '19000107', 112 ), @EndDate ) % 7 ), @EndDate ), '2100-01-01' )
    IF @EndDate < @StartDate SET @EndDate = DATEADD( day, 6 + DATEDIFF( day, @EndDate, @StartDate ), @EndDate )

	DECLARE @CampusTbl TABLE ( [Id] int )
	INSERT INTO @CampusTbl SELECT [Item] FROM ufnUtility_CsvToTable( ISNULL(@CampusIds,'') )

	DECLARE @ScheduleTbl TABLE ( [Id] int )
	INSERT INTO @ScheduleTbl SELECT [Item] FROM ufnUtility_CsvToTable( ISNULL(@ScheduleIds,'') )

	DECLARE @GroupTbl TABLE ( [Id] int )
	INSERT INTO @GroupTbl SELECT [Item] FROM ufnUtility_CsvToTable( ISNULL(@GroupIds,'') )

	SELECT B.[PersonId], B.[CampusId], B.[GroupId], B.[GroupName], B.[ScheduleId], B.[StartDateTime], B.[LocationId], B.[RoleName], B.[LocationName] 
	FROM
	(
		SELECT PA.[PersonId], ROW_NUMBER() OVER (PARTITION BY PA.[PersonId] ORDER BY A.[StartDateTime] DESC) AS PersonRowNumber,
			A.[CampusId], A.[GroupId], G.[Name] AS [GroupName], A.[ScheduleId], A.[StartDateTime], A.[LocationId], R.[RoleName], L.[Name] AS [LocationName]
		FROM [Attendance] A
		INNER JOIN [PersonAlias] PA ON PA.[Id] = A.[PersonAliasId]
		INNER JOIN [Group] G ON G.[Id] = A.[GroupId]
		INNER JOIN @GroupTbl [G2] ON [G2].[Id] = G.[Id]
		OUTER APPLY (
			SELECT TOP 1 R.[Name] AS [RoleName]
			FROM [GroupMember] M 
			INNER JOIN [GroupTypeRole] R
				ON R.[Id] = M.[GroupRoleId]
			WHERE M.[GroupId] = G.[Id]
			AND M.[PersonId] = PA.[PersonId]
			AND M.[GroupMemberStatus] <> 0
			ORDER BY R.[Order]
		) R
		LEFT OUTER JOIN [Location] L
			ON L.[Id] = A.[LocationId]
		LEFT OUTER JOIN @CampusTbl [C] ON [C].[id] = [A].[CampusId]
		LEFT OUTER JOIN @ScheduleTbl [S] ON [S].[id] = [A].[ScheduleId]
		WHERE [StartDateTime] BETWEEN @StartDate AND @EndDate
		AND [DidAttend] = 1
		AND ( 
			( @CampusIds IS NULL OR [C].[Id] IS NOT NULL ) OR  
			( @IncludeNullCampusIds = 1 AND A.[CampusId] IS NULL ) 
		)
		AND ( @ScheduleIds IS NULL OR [S].[Id] IS NOT NULL  )
	) B
	WHERE B.PersonRowNumber = 1

END