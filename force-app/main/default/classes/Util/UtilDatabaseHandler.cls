/**
 * @description Handler class for DatabaseUtil
 */
public with sharing virtual class UtilDatabaseHandler {
  private static final String CLASS_NAME = 'UtilDatabaseHandler';
  /**
   * @description Creates log based on failed save result and adds to logs list
   * @param result Save result
   */
  public static void createDatabaseErrors(Database.SaveResult result) {
    if (!result.isSuccess()) {
      createDatabaseErrorsAsLogs(result.getErrors());
    }
  }

  /**
   * @description Creates logs based on failed save results and adds to logs list
   * @param results Save result list
   */
  public static void createDatabaseErrors(Database.SaveResult[] results) {
    for (Database.SaveResult result : results) {
      if (!result.isSuccess()) {
        createDatabaseErrorsAsLogs(result.getErrors());
      }
    }
  }

  /**
   * @description Creates log based on failed upsert result and adds to logs list
   * @param result Upsert result
   */
  public static void createDatabaseErrors(Database.UpsertResult result) {
    if (!result.isSuccess()) {
      createDatabaseErrorsAsLogs(result.getErrors());
    }
  }

  /**
   * @description Creates logs based on failed upsert results and adds to logs list
   * @param results Upsert result list
   */
  public static void createDatabaseErrors(Database.UpsertResult[] results) {
    for (Database.UpsertResult result : results) {
      if (!result.isSuccess()) {
        createDatabaseErrorsAsLogs(result.getErrors());
      }
    }
  }

  /**
   * @description Creates log based on failed delete result and adds to logs list
   * @param result Delete result
   */
  public static void createDatabaseErrors(Database.DeleteResult result) {
    if (!result.isSuccess()) {
      createDatabaseErrorsAsLogs(result.getErrors());
    }
  }

  /**
   * @description Creates logs based on failed delete result and adds to logs list
   * @param results Delete result list
   */
  public static void createDatabaseErrors(Database.DeleteResult[] results) {
    for (Database.DeleteResult result : results) {
      if (!result.isSuccess()) {
        createDatabaseErrorsAsLogs(result.getErrors());
      }
    }
  }

  /**
   * @description Creates log based on failed undelete result and adds to logs list
   * @param result Undelete result
   */
  public static void createDatabaseErrors(Database.UndeleteResult result) {
    if (!result.isSuccess()) {
      createDatabaseErrorsAsLogs(result.getErrors());
    }
  }

  /**
   * @description Creates logs based on failed undelete result and adds to logs list
   * @param results Undelete result list
   */
  public static void createDatabaseErrors(Database.UndeleteResult[] results) {
    for (Database.UndeleteResult result : results) {
      if (!result.isSuccess()) {
        createDatabaseErrorsAsLogs(result.getErrors());
      }
    }
  }

  /**
   * @description Gets errors from result and creates a list with error logs
   * @param errors Errors
   */
  private static void createDatabaseErrorsAsLogs(Database.Error[] errors) {
    String METHOD_NAME = 'createDatabaseErrorsAsLogs';
    for (Database.Error error : errors) {
      // UtilLog.createErrorLog(String.valueOf(error.getStatusCode()), error.getMessage());
      system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' StatusCode: ' + error.getStatusCode() + ' Message: ' + error.getMessage());
    }
  }
}
