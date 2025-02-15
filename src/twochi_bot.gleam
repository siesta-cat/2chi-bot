import app
import backoff
import bio
import config
import gleam/io
import gleam/option
import gleam/result
import image/image
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
        Error(err) -> io.println_error("Error: " <> err)
        Ok(_) -> Nil
      }
    }
  }
}

fn run(config: app.Config, token: String) -> Result(Nil, String) {
  let max_retries = config.max_retries
  let backend_url = config.backend_url
  let instance_url = config.instance_url

  use image <- result.try(
    backoff.retry(max_retries, fn() { images.get_next_url(backend_url) }),
  )
  use image <- result.try(next_image(
    image:,
    instance_url:,
    token:,
    error_message: config.maintainers <> " " <> config.out_of_images_message,
    max_retries:,
  ))
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

fn next_image(
  image image: option.Option(image.Image),
  instance_url instance_url: String,
  token token: String,
  error_message error_message: String,
  max_retries max_retries: Int,
) -> Result(image.Image, String) {
  case image {
    option.None -> {
      let error_msg =
        backoff.retry(max_retries, fn() {
          status.post(
            instance_url,
            token,
            error_message,
            False,
            visibility.Direct,
            [],
          )
        })

      case error_msg {
        Ok(_) -> Error("Out of images")
        Error(err) -> Error(err)
      }
    }
    option.Some(image) -> {
      Ok(image)
    }
  }
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
