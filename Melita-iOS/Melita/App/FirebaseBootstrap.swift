import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions

enum AppConfig {
    /// Se usan los emuladores locales automáticamente cuando el GoogleService-Info.plist
    /// es el de prueba (PROJECT_ID empieza con "demo-"). Con el plist real de tu proyecto
    /// la app se conecta a Firebase en producción. Solo aplica en builds DEBUG.
    /// Las notificaciones push NO funcionan con emuladores.
    static var useEmulators: Bool {
        FirebaseApp.app()?.options.projectID?.hasPrefix("demo-") == true
    }

    /// En el simulador "localhost" funciona. En un iPhone físico usa la IP de tu Mac (ej. "192.168.1.20").
    static let emulatorHost = "localhost"

    /// Región de las Cloud Functions (debe coincidir con setGlobalOptions en functions/src/index.ts).
    static let functionsRegion = "europe-west1"
}

enum FirebaseBootstrap {
    static func configure() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()

        #if DEBUG
        if AppConfig.useEmulators {
            connectToEmulators()
        } else {
            print("☁️ Conectado a Firebase: \(FirebaseApp.app()?.options.projectID ?? "?")")
        }
        #endif
    }

    private static func connectToEmulators() {
        let host = AppConfig.emulatorHost
        Auth.auth().useEmulator(withHost: host, port: 9099)

        let settings = Firestore.firestore().settings
        settings.host = "\(host):8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings

        Storage.storage().useEmulator(withHost: host, port: 9199)
        Functions.functions(region: AppConfig.functionsRegion).useEmulator(withHost: host, port: 5001)
        print("⚙️ Usando emuladores de Firebase en \(host)")
    }
}
