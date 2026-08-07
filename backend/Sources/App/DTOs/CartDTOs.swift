import Vapor

struct AddCartItemRequest: Content, Validatable {
    let productID: UUID
    let quantity: Int

    static func validations(_ validations: inout Validations) {
        validations.add("quantity", as: Int.self, is: .range(1...99))
    }
}

struct UpdateCartItemRequest: Content, Validatable {
    let quantity: Int

    static func validations(_ validations: inout Validations) {
        validations.add("quantity", as: Int.self, is: .range(1...99))
    }
}
