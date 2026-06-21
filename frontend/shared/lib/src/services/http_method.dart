/// Supported HTTP verbs for [ApiService.request].
///
/// Use [HttpMethod.multipart] for file uploads — body fields go into
/// `body`, files go into the `files` parameter.
enum HttpMethod { get, post, put, patch, delete, multipart }
