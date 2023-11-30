Write-Output "JOB START"
$adminUser = Get-AutomationVariable -Name "DATABASEADMINUSERNAME"
$adminPassword = Get-AutomationVariable -Name "DATABASEADMINPASSWORD"
$serverName = Get-AutomationVariable -Name "DATABASESERVERNAME"
$databaseName = Get-AutomationVariable -Name "DATABASENAME"
$MasterDatabaseConnection = New-Object System.Data.SqlClient.SqlConnection
$MasterDatabaseConnection.ConnectionString = "Data Source=$serverName.database.windows.net,1433;Initial Catalog=$databaseName;User Id=$adminUser;Password=$adminPassword;"
$MasterDatabaseCommand = New-Object System.Data.SqlClient.SqlCommand
$MasterDatabaseCommand.Connection = $MasterDatabaseConnection
$MasterDatabaseCommand.CommandText = @"
UPDATE Jobs
SET Jobs.[Queued] = Jobs.[NewQueued]
FROM (
  SELECT
    SortedJobs.[Queued]
	,DATEADD(ms, ROW_NUMBER() OVER(ORDER BY CASE
      WHEN JobUser.MetadataValue = 'sitecore\job_productcatalog' THEN 99
	  WHEN JobUser.MetadataValue = 'sitecore\job_cdnmedia' THEN 98
--    WHEN JobUser.MetadataValue = 'sitecore\job_productcatalog' AND JobLanguage.MetadataValue = 'fr-CA' THEN 97
	  WHEN JobItem.MetadataValue = '{A6FE23E8-34D9-4997-867F-CBDB69D08FA5}' THEN 96 -- /shared
	  WHEN JobItem.MetadataValue = '{666D78EE-9503-4A34-B0D6-533EE1A3EA12}' THEN 95 -- /shared/data
	  WHEN JobItem.MetadataValue = '{22DE8026-23FD-40B7-B0C6-4ECB5B453D54}' THEN 94 -- /shared/data/product data
	  WHEN JobItem.MetadataValue = '{9A71B6D6-D064-4155-885A-9E6074F3D892}' THEN 93 -- /shared datasources
      WHEN JobRelated.MetadataValue = 'True' THEN 92
      ELSE 0
      END ASC, SortedJobs.[Queued] ASC), RunningJob.[Queued]) AS [NewQueued]
  FROM [dbo].[Publishing_JobQueue] SortedJobs
  LEFT JOIN [dbo].[Publishing_JobMetadata] JobUser ON SortedJobs.[JobId] = JobUser.[JobId] AND JobUser.MetadataKey = 'Publish.Options.User'
  LEFT JOIN [dbo].[Publishing_JobMetadata] JobItem ON SortedJobs.[JobId] = JobItem.[JobId] AND JobItem.MetadataKey = 'Publish.Options.ItemId'
  LEFT JOIN [dbo].[Publishing_JobMetadata] JobRelated ON SortedJobs.[JobId] = JobRelated.[JobId] AND JobRelated.MetadataKey = 'Publish.Options.IncludeRelatedItems'
--LEFT JOIN [dbo].[Publishing_JobMetadata] JobLanguage ON SortedJobs.[JobId] = JobLanguage.[JobId] AND JobLanguage.MetadataKey = 'Publish.Options.Languages'
  CROSS JOIN [dbo].[Publishing_JobQueue] RunningJob
  WHERE SortedJobs.[Status] = 0 AND RunningJob.[Status] = 1
) AS Jobs
"@
$MasterDatabaseConnection.Open()
$MasterDatabaseCommand.ExecuteNonQuery()
$MasterDatabaseConnection.Close() 
Write-Output "JOB END"
