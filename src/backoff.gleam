import gleam/erlang/process
import gleam/int
import gleam/io

pub fn retry(
  retries: Int,
  fun: fn() -> Result(result, String),
) -> Result(result, String) {
  backoff(retries, 1, "Max Retries Reached", fun)
}

fn backoff(
  retries: Int,
  delay: Int,
  error: String,
  fun: fn() -> Result(result, String),
) {
  case retries {
    0 -> Error(error)
    _ ->
      case fun() {
        Error(err) -> {
          io.println_error("Retry " <> int.to_string(retries) <> ": " <> err)
          process.sleep(delay)
          let delay = delay * 2
          let retries = retries - 1
          backoff(retries, delay, err, fun)
        }
        Ok(result) -> Ok(result)
      }
  }
}
