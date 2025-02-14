pub type Visibility {
  Public
  Unlisted
  Private
  Direct
}

pub fn to_string(visibility: Visibility) -> String {
  case visibility {
    Direct -> "direct"
    Private -> "private"
    Public -> "public"
    Unlisted -> "unlisted"
  }
}
