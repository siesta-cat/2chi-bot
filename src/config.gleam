import app
import gleam/option
import gleam/result
import glenvy/env

pub fn load_from_env() -> Result(app.Config, String) {
  let instance_bio =
    result.unwrap(
      read_env_var("INSTANCE_BIO", env.get_string),
      "A bot that post images",
    )
  let out_of_images_message =
    result.unwrap(
      read_env_var("OUT_OF_IMAGES_MESSAGE", env.get_string),
      "I am out of images",
    )
  let max_retries = result.unwrap(read_env_var("MAX_RETRIES", env.get_int), 5)
  let instance_token =
    option.from_result(
      read_env_var("INSTANCE_TOKEN", fn(env) { env.get_string(env) }),
    )

  use instance_url <- result.try(read_env_var("INSTANCE_URL", env.get_string))
  use backend_url <- result.try(read_env_var("BACKEND_URL", env.get_string))
  use maintainers <- result.try(read_env_var("BOT_MAINTAINERS", env.get_string))

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
  read_fun: fn(String) -> Result(a, env.Error),
) -> Result(a, String) {
  read_fun(name)
  |> result.replace_error("Incorrect value for env var '" <> name <> "'")
}
