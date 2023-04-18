import gleam/pgo
import gleam/uri
import gleam/option
import gleam/list
import gleam/result
import gleam/bit_builder.{BitBuilder}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import packages/store
import packages/web/page

pub type Context {
  Context(db: pgo.Connection, request: Request(BitString))
}

pub fn make_service(
  db: pgo.Connection,
) -> fn(Request(BitString)) -> Response(BitBuilder) {
  fn(request) {
    let context = Context(db: db, request: request)
    handle_request(context)
  }
}

pub fn handle_request(context: Context) -> Response(BitBuilder) {
  let search_term =
    context.request.query
    |> option.to_result(Nil)
    |> result.then(uri.parse_query)
    |> result.then(list.key_find(_, "search"))
    |> result.unwrap("")
  let assert Ok(packages) = store.search_packages(context.db, search_term)

  let html = page.packages_index(packages, search_term)
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(html)
}