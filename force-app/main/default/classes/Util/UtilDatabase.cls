/**
 * @description Database util class
 */
public with sharing class UtilDatabase extends UtilDatabaseHandler {
  /**
   * @description Inserts record
   * @param record Record to be inserted
   * @param allOrNone Insert all or none
   * @return List of Database.SaveResult
   */
  public static Database.SaveResult insertRecords(sObject record, Boolean allOrNone) {
    Database.SaveResult result = Database.insert(record, allOrNone);
    createDatabaseErrors(result);
    return result;
  }

  /**
   * @description Inserts records
   * @param records Records to be inserted
   * @param allOrNone Insert all or none
   * @return Database.SaveResult
   */
  public static List<Database.SaveResult> insertRecords(List<sObject> records, Boolean allOrNone) {
    Database.SaveResult[] results = Database.insert(records, allOrNone);
    createDatabaseErrors(results);
    return results;
  }

  /**
   * @description Updates record
   * @param record Record to be updated
   * @param allOrNone Update all or none
   * @return Database.SaveResult
   */
  public static Database.SaveResult updateRecords(sObject record, Boolean allOrNone) {
    Database.SaveResult result = Database.update(record, allOrNone);
    createDatabaseErrors(result);
    return result;
  }

  /**
   * @description Updates records
   * @param records Records to be updated
   * @param allOrNone Update all or none
   * @return List of Database.SaveResult
   */
  public static List<Database.SaveResult> updateRecords(List<sObject> records, Boolean allOrNone) {
    Database.SaveResult[] results = Database.update(records, allOrNone);
    createDatabaseErrors(results);
    return results;
  }

  /**
   * @description Upserts record
   * @param record Record to be upserted
   * @param allOrNone Upsert all or none
   * @return Database.UpsertResult
   */
  public static Database.UpsertResult upsertRecords(sObject record, Boolean allOrNone) {
    Database.UpsertResult result = Database.upsert(record, allOrNone);
    createDatabaseErrors(result);
    return result;
  }

  /**
   * @description Upserts records
   * @param records Records to be upserted
   * @param allOrNone Upsert all or none
   * @return List of Database.UpsertResult
   */
  public static List<Database.UpsertResult> upsertRecords(List<sObject> records, Boolean allOrNone) {
    Database.UpsertResult[] results = Database.upsert(records, allOrNone);
    createDatabaseErrors(results);
    return results;
  }

  /**
   * @description Deletes record
   * @param recordId Id of the record to be deleted
   * @param allOrNone Delete all or none
   * @return Database.UndeleteResult
   */
  public static Database.DeleteResult deleteRecords(String recordId, Boolean allOrNone) {
    Database.DeleteResult result = Database.delete(recordId, allOrNone);
    createDatabaseErrors(result);
    return result;
  }

  /**
   * @description Deletes records
   * @param recordIds Ids of the records to be deleted
   * @param allOrNone Delete all or none
   * @return List of Database.UndeleteResult
   */
  public static List<Database.DeleteResult> deleteRecords(List<String> recordIds, Boolean allOrNone) {
    Database.DeleteResult[] results = Database.delete(recordIds, allOrNone);
    createDatabaseErrors(results);
    return results;
  }

  /**
   * @description Undeletes record
   * @param recordId Id of the record to be undeleted
   * @param allOrNone Undelete all or none
   * @return Database.UndeleteResult
   */
  public static Database.UndeleteResult undeleteRecords(String recordId, Boolean allOrNone) {
    Database.UndeleteResult result = Database.undelete(recordId, allOrNone);
    createDatabaseErrors(result);
    return result;
  }

  /**
   * @description Undeletes records
   * @param recordIds Ids of the records to be undeleted
   * @param allOrNone Undelete all or none
   * @return List of Database.UndeleteResult
   */
  public static List<Database.UndeleteResult> undeleteRecords(List<String> recordIds, Boolean allOrNone) {
    Database.UndeleteResult[] results = Database.undelete(recordIds, allOrNone);
    createDatabaseErrors(results);
    return results;
  }

  /**
   * @description Publishes events
   * @param events Events to be inserted
   * @return List of Database.SaveResult
   */
  public static List<Database.SaveResult> publishEvents(List<sObject> events) {
    Database.SaveResult[] results = Eventbus.publish(events);
    createDatabaseErrors(results);
    return results;
  }
}
