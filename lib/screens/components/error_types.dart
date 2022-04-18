const ERROR_TYPE_NETWORK = "NETWORK_ERROR";
const ERROR_TYPE_PERMISSION = "PERMISSION_ERROR";
const ERROR_TYPE_TIME = "TIME_ERROR";
const ERROR_TYPE_UNDER_REVIEW = "UNDER_VIEW_ERROR";

// 错误的类型, 方便照展示和谐的提示
String errorType(String error) {
  if (error.contains("timeout") ||
      error.contains("connection refused") ||
      error.contains("deadline") ||
      error.contains("connection abort")) {
    return ERROR_TYPE_NETWORK;
  }
  if (error.contains("permission denied")) {
    return ERROR_TYPE_PERMISSION;
  }
  if (error.contains("time is not synchronize")) {
    return ERROR_TYPE_TIME;
  }
  if (error.contains("under review")) {
    return ERROR_TYPE_UNDER_REVIEW;
  }
  return "";
}
