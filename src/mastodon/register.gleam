import gleam/dynamic/decode
import gleam/erlang
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result
import gleam/string

fn decode_app_register() {
  use client_id <- decode.field("client_id", decode.string)
  use client_secret <- decode.field("client_secret", decode.string)
  decode.success(#(client_id, client_secret))
}

fn decode_token() {
  use token <- decode.field("access_token", decode.string)
  decode.success(token)
}

const redirect_uri = "urn:ietf:wg:oauth:2.0:oob"

const app_name = "image_bot"

const scopes = "read write admin"

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
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    })

  let assert Ok(#(client_id, client_secret)) =
    json.parse(response.body, decode_app_register())

  io.println("Please enter into the following url to authrise:")
  io.println(
    instance
    <> "/oauth/authorize?client_id="
    <> client_id
    <> "&redirect_uri="
    <> redirect_uri
    <> "&response_type=code&scope=read%20write%20admin",
  )
  let assert Ok(token) =
    erlang.get_line("Please provide me with the token: ")
    |> result.map(string.trim)

  let json =
    json.object([
      #("client_id", json.string(client_id)),
      #("client_secret", json.string(client_secret)),
      #("grant_type", json.string("authorization_code")),
      #("redirect_uri", json.string(redirect_uri)),
      #("code", json.string(token)),
    ])

  let assert Ok(req) =
    request.to(instance <> "/oauth/token")
    |> result.replace_error("Failed to parse url '" <> instance <> "'")

  let req =
    req
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(json))
    |> request.set_method(http.Post)

  let assert Ok(response) =
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    })

  let assert Ok(token) = json.parse(response.body, decode_token())

  io.println(
    "Please next time boot me with this token in the INSTANCE_TOKEN env var: "
    <> token,
  )
}
