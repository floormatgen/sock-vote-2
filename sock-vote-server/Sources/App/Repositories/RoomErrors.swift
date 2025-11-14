import Hummingbird


/// A namespace for Room-related errors
enum RoomError {

    /// Thrown when a room isn't found
    struct NotFound: HTTPResponseError {

        var code: String

        var status: HTTPResponse.Status { .notFound }

        init(code: String) {
            self.code = code
        }

        func response(from request: Request, context: some RequestContext) throws -> Response {
            return Response(status: self.status)
        }
    }

    /// Thrown when a code can't be found for a room
    struct FailedToGenerateCode: HTTPResponseError {

        var status: HTTPResponse.Status { .internalServerError }

        func response(from request: Request, context: some RequestContext) throws -> Response {
            return Response(status: self.status)
        }

    }

}
