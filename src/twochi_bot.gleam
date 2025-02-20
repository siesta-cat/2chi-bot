import app
import backoff
import bio
import config
import gleam/io
import gleam/option
import gleam/result
import image/status as image_status
import images
import mastodon/media
import mastodon/register
import mastodon/status
import mastodon/visibility

pub fn main() {
  let assert Ok(config) = config.load_from_env()
  case config.instance_token {
    option.None -> {
      register.register(config.instance_url)
    }
    option.Some(token) -> {
      case run(config, token) {
        Error(err) -> {
          io.println_error("Error: " <> err)
          let error_post_body = config.maintainers <> " " <> err
          case
            backoff.retry(config.max_retries, fn() {
              status.post(
                config.instance_url,
                token,
                error_post_body,
                False,
                visibility.Direct,
                [],
              )
            })
          {
            Error(err) -> io.println_error("Error: " <> err)
            Ok(_) -> Nil
          }
          panic as err
        }
        Ok(_) -> Nil
      }
    }
  }
}

fn run(config: app.Config, token: String) -> Result(Nil, String) {
  let max_retries = config.max_retries
  let backend_url = config.backend_url
  let instance_url = config.instance_url
  let out_of_images = config.out_of_images_message

  use image <- result.try(
    backoff.retry(max_retries, fn() { images.get_next_url(backend_url) }),
  )
  use image <- result.try(option.to_result(image, out_of_images))
  io.println("Got new image to post, url: " <> image.url)

  use status <- result.try(
    backoff.retry(max_retries, fn() {
      post_image(
        instance_url:,
        token:,
        image_url: image.url,
        visibility: visibility.Unlisted,
      )
    }),
  )
  io.println("Posted new status, id: " <> status.id)

  use _ <- result.try(
    backoff.retry(max_retries, fn() {
      images.change_status(backend_url, image.id, image_status.Consumed)
    }),
  )
  io.println("Change image(" <> image.id <> ") status to consumed")

  use bio <- result.try(
    backoff.retry(max_retries, fn() {
      bio.update_bio(backend_url, instance_url, token, config.instance_bio)
    }),
  )
  io.println("Updated bio contents, new content: " <> bio)

  Ok(io.println("DONE!"))
}

pub fn post_image(
  instance_url instance_url: String,
  token instance_token: String,
  image_url image_url: String,
  visibility visibility: visibility.Visibility,
) -> Result(status.Status, String) {
  use image <- result.try(images.fetch_url(image_url))
  use uploaded_image <- result.try(media.upload(
    instance_url,
    instance_token,
    image,
    image_url,
  ))
  status.post(
    url: instance_url,
    token: instance_token,
    status: "",
    sensitive: True,
    visibility:,
    media_ids: [uploaded_image],
  )
}
