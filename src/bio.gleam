import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import images

pub fn update_bio(
  url instance_url: String,
  token instance_token: String,
  bio instance_bio: String,
) -> Result(String, String) {
  use req <- result.try(
    request.to(instance_url <> "/images?status=available")
    |> result.replace_error("Failed to parse url '" <> instance_url <> "'"),
  )

  let req = request.set_method(req, http.Get)

  use resp <- result.try(
    httpc.send(req) |> result.replace_error("Failed to make request"),
  )

  use images <- result.try(
    json.parse(resp.body, images.images_decoder())
    |> result.replace_error("Failed to parse post"),
  )

  let new_bio =
    instance_bio
    <> "\n\n"
    <> int.to_string(list.length(images))
    <> " new images remaining"

  let json = json.object([#("note", json.string(new_bio))])

  use req <- result.try(
    request.to(instance_url <> "/api/v1/accounts/update_credentials")
    |> result.replace_error("Failed to parse url '" <> instance_url <> "'"),
  )

  let req =
    request.set_header(req, "Authorization", "Bearer " <> instance_token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(json))
    |> request.set_method(http.Post)

  use resp <- result.try(
    httpc.send(req) |> result.replace_error("Failed to make request"),
  )

  case resp.status {
    200 -> Ok(new_bio)
    _ -> Error("Failed to update bio")
  }
}
