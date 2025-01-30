import ToucanModels

extension ContentDefinition.Mocks {

    static func page() -> ContentDefinition {
        .init(
            type: "page",
            paths: [
                "pages"
            ],
            properties: [
                "title": .init(
                    type: .string,
                    required: true,
                    default: nil
                ),
                "description": .init(
                    type: .string,
                    required: true,
                    default: nil
                ),
            ],
            relations: [:],
            queries: [:]
        )
    }
}
