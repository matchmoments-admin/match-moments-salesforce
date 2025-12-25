// Abort all scheduled jobs to allow deployment
List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger];
System.debug('Found ' + scheduledJobs.size() + ' scheduled jobs');

for (CronTrigger job : scheduledJobs) {
    try {
        System.abortJob(job.Id);
        System.debug('Aborted job: ' + job.CronJobDetail.Name);
    } catch (Exception e) {
        System.debug('Error aborting job ' + job.CronJobDetail.Name + ': ' + e.getMessage());
    }
}

System.debug('All scheduled jobs aborted');

