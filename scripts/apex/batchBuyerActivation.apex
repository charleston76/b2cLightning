// try again in a minute
Datetime sysTime = System.now().addSeconds( 30 );
String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
system.debug('chronExpression ' + chronExpression);
System.schedule( 'D2CScheduleBuyerActivation ' + sysTime, chronExpression, new D2CScheduleBuyerActivation());


/******************************************
 * 
 * To cancell the schedules
 *
// 
for(CronTrigger ct : [
    SELECT Id, CronJobDetail.Name, CronJobDetail.JobType 
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE 'D2CScheduleBuyerActivation%' 
    LIMIT 50]){
    try{
        system.debug('CronTrigger id ' + ct.id);
        system.abortJob(ct.id);
    }
    catch (exception e) {}
}

for(AsyncApexJob ct : [
    SELECT ApexClassId,CompletedDate,CreatedById,CreatedDate,ExtendedStatus,Id,JobItemsProcessed,JobType,LastProcessed,LastProcessedOffset,MethodName,NumberOfErrors,ParentJobId,Status,TotalJobItems 
    FROM AsyncApexJob 
    WHERE status = 'queue' 
    LIMIT 50]){
    try{
        system.debug('AsyncApexJob id ' + ct.id);
        system.abortJob(ct.id);
    }
    catch (exception e) {}
}
*/