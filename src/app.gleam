import gleam/option

pub type Config {
  Config(
    instance_url: String,
    instance_bio: String,
    instance_token: option.Option(String),
    backend_url: String,
    maintainers: String,
    out_of_images_message: String,
    max_retries: Int,
  )
}
