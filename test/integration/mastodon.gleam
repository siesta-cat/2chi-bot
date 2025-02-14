import config
import gleam/option
import mastodon/status
import mastodon/visibility

pub fn post_should_post_test() {
  let assert Ok(config) = config.load_from_env()

  let assert option.Some(token) = config.instance_token
  let url = config.instance_url

  let assert Ok(status) =
    status.post(
      url:,
      token:,
      status: "TEST!",
      sensitive: False,
      visibility: visibility.Direct,
      media_ids: [],
    )

  let assert Ok(_) = status.delete(url, token, status.id)
}
