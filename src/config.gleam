import app
import envoy
import gleam/int
import gleam/option
import gleam/result

pub fn load_from_env() -> Result(app.Config, String) {
  let instance_bio =
    result.unwrap(read_env_var("INSTANCE_BIO", Ok(_)), "A bot that post images")
  let out_of_images_message =
    result.unwrap(
      read_env_var("OUT_OF_IMAGES_MESSAGE", Ok(_)),
      "I am out of images",
    )
  let max_retries = result.unwrap(read_env_var("MAX_RETRIES", int.parse), 5)
  let instance_token = option.from_result(read_env_var("INSTANCE_TOKEN", Ok(_)))

  use instance_url <- result.try(read_env_var("INSTANCE_URL", Ok(_)))
  use backend_url <- result.try(read_env_var("BACKEND_URL", Ok(_)))
  use maintainers <- result.try(read_env_var("BOT_MAINTAINERS", Ok(_)))

  Ok(app.Config(
    instance_url:,
    instance_bio:,
    instance_token:,
    backend_url:,
    maintainers:,
    out_of_images_message:,
    max_retries:,
  ))
}

fn read_env_var(
  name: String,
  read_fun: fn(String) -> Result(a, error),
) -> Result(a, String) {
  envoy.get(name)
  |> result.replace_error("Env var '" <> name <> "' not found")
  |> result.map(fn(value) {
    read_fun(value)
    |> result.replace_error("Incorrect value for env var '" <> name <> "'")
  })
  |> result.flatten()
}
