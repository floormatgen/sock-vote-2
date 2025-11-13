import Hummingbird

struct RoomController<Repository: RoomRepository> {

    /// The repository to use to find and access rooms
    let repository: Repository

    var routes: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get(":code", use: self.getRoom)
    }

    @Sendable
    func getRoom(request: Request, context: some RequestContext) async throws -> RoomInfo {
        let code = try context.parameters.require("code")

        guard let room = try await repository.findRoom(code: code) else {
            #warning("TODO: Create HTTPResponseError when a room can't be found")
            fatalError()
        }

        return room
    }

    struct CreateRoomRequest: Decodable {
        let name: String
    }

    @Sendable
    func createRoom(request: Request, context: some RequestContext) async throws -> FullRoomInfo {
        let createRequest = try await request.decode(as: CreateRoomRequest.self, context: context)
        return try await repository.addRoom(name: createRequest.name)
    }

}