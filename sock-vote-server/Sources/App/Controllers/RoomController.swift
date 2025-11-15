import Hummingbird

struct RoomController<Repository: RoomRepository> {

    /// The repository to use to find and access rooms
    let repository: Repository

    var routes: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get(":code", use: self.getRoom)
            .post(use: self.createRoom)
    }

    @Sendable
    func getRoom(request: Request, context: some RequestContext) async throws -> Room.Info {
        let code = try context.parameters.require("code")
        let room = try await repository.findRoom(code: code)
        return room  
    }

    struct CreateRoomRequest: Decodable {
        let name: String
    }

    @Sendable
    func createRoom(request: Request, context: some RequestContext) async throws -> Room.FullInfo {
        let createRequest = try await request.decode(as: CreateRoomRequest.self, context: context)
        return try await repository.addRoom(name: createRequest.name)
    }

}
