import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string
import mastodon/visibility

pub type Status {
  Status(id: String, media_attachments: List(String))
}

fn decode_media_attachments() {
  use url <- decode.field("url", decode.string)
  decode.success(url)
}

fn decode_post() {
  use id <- decode.field("id", decode.string)
  use media_attachments <- decode.field(
    "media_attachments",
    decode.list(decode_media_attachments()),
  )
  decode.success(Status(id:, media_attachments:))
}

pub fn get(
  instance_url: String,
  instance_token: String,
  post_id: String,
) -> Result(Status, String) {
  use req <- result.try(
    request.to(instance_url <> "/api/v1/statuses/" <> post_id)
    |> result.replace_error("Failed to parse url '" <> instance_url <> "'"),
  )

  let req =
    request.set_header(req, "Authorization", "Bearer " <> instance_token)
    |> request.set_method(http.Get)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  json.parse(resp.body, decode_post())
  |> result.replace_error("Failed to parse images: " <> resp.body)
}

pub fn delete(
  instance_url: String,
  instance_token: String,
  post_id: String,
) -> Result(Status, String) {
  use req <- result.try(
    request.to(instance_url <> "/api/v1/statuses/" <> post_id)
    |> result.replace_error("Failed to parse url '" <> instance_url <> "'"),
  )

  let req =
    request.set_header(req, "Authorization", "Bearer " <> instance_token)
    |> request.set_method(http.Delete)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  json.parse(resp.body, decode_post())
  |> result.replace_error("Failed to parse images: " <> resp.body)
}

pub fn post(
  url instance_url: String,
  token instance_token: String,
  status status: String,
  sensitive sensitive: Bool,
  visibility visibility: visibility.Visibility,
  media_ids media_ids: List(String),
) -> Result(Status, String) {
  let json =
    json.object([
      #("status", json.string(status)),
      #("sensitive", json.bool(sensitive)),
      #("visibility", json.string(visibility.to_string(visibility))),
      #("media_ids", json.array(media_ids, json.string)),
    ])

  use req <- result.try(
    request.to(instance_url <> "/api/v1/statuses")
    |> result.replace_error("Failed to parse url '" <> instance_url <> "'"),
  )

  let idem_key = status <> string.concat(media_ids)

  let req =
    request.set_header(req, "Authorization", "Bearer " <> instance_token)
    |> request.set_header("content-type", "application/json")
    |> request.set_header("Idempotency-Key", idem_key)
    |> request.set_body(json.to_string(json))
    |> request.set_method(http.Post)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  json.parse(resp.body, decode_post())
  |> result.replace_error("Failed to parse images: " <> resp.body)
}
