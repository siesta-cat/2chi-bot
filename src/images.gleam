import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import image/image
import image/status

pub fn images_decoder() {
  use images <- decode.field("images", decode.list(image.decoder()))
  decode.success(images)
}

pub fn fetch_url(url: String) -> Result(BitArray, String) {
  use req <- result.try(
    request.to(url)
    |> result.replace_error("Failed to parse url '" <> url <> "'"),
  )
  let req =
    req
    |> request.set_body(<<>>)
    |> request.set_method(http.Get)

  use resp <- result.try(
    httpc.send_bits(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  Ok(resp.body)
}

pub fn change_status(
  backend_url: String,
  id: String,
  status: status.Status,
) -> Result(Nil, String) {
  let json = json.object([#("status", json.string(status.to_string(status)))])

  use req <- result.try(
    request.to(backend_url <> "/images/" <> id)
    |> result.replace_error("Failed to parse url '" <> backend_url <> "'"),
  )

  let req =
    req
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(json))
    |> request.set_method(http.Put)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  case resp.status {
    204 -> Ok(Nil)
    _ -> Error("Failed to update status, response: " <> string.inspect(resp))
  }
}

pub fn get_next_url(
  backend_url: String,
) -> Result(option.Option(image.Image), String) {
  use req <- result.try(
    request.to(backend_url <> "/images?status=available&limit=1")
    |> result.replace_error("Failed to parse url '" <> backend_url <> "'"),
  )

  let req = request.set_method(req, http.Get)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      "Failed to make request: " <> string.inspect(err)
    }),
  )

  use images <- result.try(
    json.parse(resp.body, images_decoder())
    |> result.replace_error("Failed to parse images: " <> resp.body),
  )

  Ok(list.first(images) |> option.from_result)
}
