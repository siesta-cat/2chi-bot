import gleam/bit_array
import gleam/list

pub type MultipartForm {
  MultipartForm(elements: List(#(String, MultipartFormBody)), boundary: String)
}

pub type MultipartFormBody {
  String(String)
  File(name: String, content: BitArray)
}

pub fn to_bit_array(form: MultipartForm) -> BitArray {
  let boundary = <<"--":utf8, form.boundary:utf8>>

  list.map(form.elements, fn(element) {
    let #(field, element) = element
    body_to_bit_array(field, element, boundary)
  })
  |> list.append([boundary, <<"--">>])
  |> bit_array.concat
}

fn body_to_bit_array(
  field: String,
  element: MultipartFormBody,
  boundary: BitArray,
) -> BitArray {
  let body = case element {
    File(filename, content) -> <<
      "Content-Disposition: form-data; name=\"":utf8,
      field:utf8,
      "\"; filename=\"":utf8,
      filename:utf8,
      "\"\nContent-Type: image/png\n\n":utf8,
      content:bits,
    >>
    String(content) -> <<
      "Content-Disposition: form-data; name=\"":utf8,
      field:utf8,
      "\"\n\n":utf8,
      content:utf8,
    >>
  }

  bit_array.concat([boundary, <<"\n">>, body, <<"\n">>])
}
