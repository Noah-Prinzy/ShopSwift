import App
import Vapor

var environment = try Environment.detect()
try LoggingSystem.bootstrap(from: &environment)

let application = try await Application.make(environment)
defer {
    Task {
        try await application.asyncShutdown()
    }
}

try configure(application)
try await application.execute()
