import config
import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option
import gleam/result
import gleeunit/should
import mastodon/status
import mastodon/visibility
import twochi_bot

pub fn post_image_works_test() {
  let test_url =
    "https://2.gravatar.com/avatar/be8eb8426d68e4beb50790647eda6f6b"
  let assert Ok(config) = config.load_from_env()

  let instance_url = config.instance_url
  let assert option.Some(token) = config.instance_token

  let assert Ok(status) =
    twochi_bot.post_image(instance_url, token, test_url, visibility.Direct)

  let assert Ok(status) = status.delete(instance_url, token, status.id)

  let assert Ok(image_url) =
    list.first(status.media_attachments)
    |> result.replace_error("Image URL not found in status")

  let assert Ok(req) = request.to(image_url)

  let req =
    request.set_header(req, "Authorization", "Bearer " <> token)
    |> request.set_body(<<>>)
    |> request.set_method(http.Get)

  let assert Ok(resp) =
    httpc.send_bits(req) |> result.replace_error("Failed to make request")

  should.be_true(bit_array.byte_size(resp.body) > 0)
}
