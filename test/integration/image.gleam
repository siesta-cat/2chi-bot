import app
import config
import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import gleeunit/should
import image/image
import image/status
import images

pub fn fetch_url_should_fetch_test() {
  let test_url =
    "https://2.gravatar.com/avatar/be8eb8426d68e4beb50790647eda6f6b"

  let assert Ok(file) = images.fetch_url(test_url)
  should.be_true(bit_array.byte_size(file) > 0)
}

pub fn get_next_url_works_test() {
  let assert Ok(config) = config.load_from_env()
  let assert Ok(initial_image) =
    insert_image(config, "https://picsum.photos/id/1")

  let assert Ok(image) = images.get_next_url(config.backend_url)

  image |> should.equal(option.Some(initial_image))

  let assert Ok(_) =
    images.change_status(config.backend_url, initial_image.id, status.Consumed)

  let assert Ok(req) =
    request.to(config.backend_url <> "/images/" <> initial_image.id)
    |> result.replace_error(
      "Failed to parse url '" <> config.backend_url <> "'",
    )

  let req = request.set_method(req, http.Get)

  let assert Ok(resp) =
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    })

  let assert Ok(image) =
    json.parse(resp.body, image.decoder())
    |> result.replace_error("Failed to parse images: " <> resp.body)

  image.url |> should.equal(initial_image.url)
  image.tags |> should.equal(initial_image.tags)
  image.status |> should.equal(status.Consumed)

  let assert Ok(image) = images.get_next_url(config.backend_url)

  should.be_none(image)
}

fn insert_image(config: app.Config, url: String) -> Result(image.Image, String) {
  let json =
    json.object([
      #("url", json.string(url)),
      #("tags", json.array(["2girl", "sleeping"], json.string)),
      #("status", json.string(status.to_string(status.Available))),
    ])

  use req <- result.try(
    request.to(config.backend_url <> "/images")
    |> result.replace_error(
      "Failed to parse url '" <> config.backend_url <> "'",
    ),
  )

  let req =
    req
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(json))
    |> request.set_method(http.Post)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  json.parse(resp.body, image.decoder())
  |> result.replace_error("Failed to parse images: " <> resp.body)
}
