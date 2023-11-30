# Prioritize Sitecore Publishing Queue
This PowerShell+SQL script will move longer-running Sitecore Publishing Service jobs to the back of the queue to allow important content authors jobs to execute first.

The script should be set up to execute at a regular interval. This can be done using a Runbook with Azure Automation or as a regular SQL agent job.

You can specify the criteria in the CASE statement to set the priority order of jobs in the queue. This can be based on the name of the user that triggered the job or the name of the item being published.

e.g. If you have a long-running publish job that runs after importing a large amount of data, you could have those pushed to the back of the queue so they only execute after all the smaller content author jobs have been completed.
