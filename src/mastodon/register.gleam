import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result

fn decode_app_register() {
  use client_id <- decode.field("client_id", decode.string)
  decode.success(client_id)
}

const redirect_uri = "urn:ietf:wg:oauth:2.0:oob"

const app_name = "image_bot"

const scopes = "read write"

pub fn register(instance: String) -> Nil {
  let json =
    json.object([
      #("client_name", json.string(app_name)),
      #("redirect_uris", json.string(redirect_uri)),
      #("scopes", json.string(scopes)),
    ])

  let assert Ok(req) =
    request.to(instance <> "/api/v1/apps")
    |> result.replace_error("Failed to parse url '" <> instance <> "'")

  let req =
    req
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(json))
    |> request.set_method(http.Post)

  let assert Ok(response) =
    httpc.send(req) |> result.replace_error("Failed to make request")

  let assert Ok(client_id) = json.parse(response.body, decode_app_register())

  io.println("Please enter into the following url to authrise:")
  io.println(
    instance
    <> "/oauth/authorize?client_id="
    <> client_id
    <> "&redirect_uri="
    <> redirect_uri
    <> "&response_type=code&scope=write",
  )
  io.println(
    "Please next time boot me with the token in the INSTANCE_TOKEN env var",
  )
}
