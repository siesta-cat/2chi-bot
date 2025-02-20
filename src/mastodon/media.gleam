import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import multipart_form
import multipart_form/field

pub fn upload(
  instance_url: String,
  instance_token: String,
  image: BitArray,
  alt: String,
) -> Result(String, String) {
  let form = [
    #("description", field.String(alt)),
    #(
      "file",
      field.File(name: "image.png", content_type: "image/png", content: image),
    ),
  ]

  use req <- result.try(
    request.to(instance_url <> "/api/v2/media")
    |> result.replace_error("Failed to parse url '" <> instance_url <> "'"),
  )

  let req =
    request.set_header(req, "Authorization", "Bearer " <> instance_token)
    |> multipart_form.to_request(form)
    |> request.set_method(http.Post)

  use resp <- result.try(
    httpc.send_bits(req)
    |> result.replace_error("Failed to make request"),
  )

  use body <- result.try(
    bit_array.to_string(resp.body)
    |> result.replace_error("Recieved non UTF-8 body"),
  )

  json.parse(body, decode())
  |> result.replace_error("Failed to parse image upload")
}

fn decode() {
  use id <- decode.field("id", decode.string)
  decode.success(id)
}
