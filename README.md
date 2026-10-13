# Melita 💞

App iOS (SwiftUI) + Firebase para que una pareja registre cosas por **categorías** (ej. "Chocolates 🍫"),
cada registro con **foto y descripción**, y la otra persona reciba una **notificación push** al instante.

```
Melita/
├── Melita-iOS/                         App iOS
│   ├── Melita.xcodeproj      ← ábrelo en Xcode
│   ├── Config/                  Info.plist (push) + entitlements
│   └── Melita/
│       ├── App/                 Entrada de la app, AppDelegate (push), configuración de Firebase
│       ├── Models/              AppUser, TrackerCategory, TrackerEntry
│       ├── Services/            Rutas de Firestore, subida de fotos, tokens de push
│       ├── Stores/              Sesión, categorías y registros (tiempo real)
│       └── Views/               Login, vincular pareja, categorías, registros, ajustes
└── Melita-Firebase/                    Backend
    ├── firebase.json            Config + emuladores
    ├── firestore.rules          Seguridad: solo la pareja ve sus datos
    ├── storage.rules            Seguridad de las fotos
    └── functions/src/index.ts   Vincular pareja + notificaciones + contadores
```

## Cómo funciona

| Funcionalidad | Cómo |
|---|---|
| Login | Firebase Auth con correo y contraseña |
| Vincular pareja | Uno toca **"Generar mi código"** (6 caracteres, dura 48 h) y el otro lo escribe. La Cloud Function `joinCouple` crea `couples/{id}` y vincula a ambos. |
| Ver datos del otro | Pestañas **"Lo mío"** y **"[nombre de tu pareja]"**. Las reglas de Firestore solo dejan leer a los dos miembros. |
| Categorías | Nombre + emoji + foto de portada. Cada quien crea las suyas. |
| Registros | Foto (cámara o galería) + descripción. Contadores: total, hoy, semana, mes. |
| Notificaciones | `onEntryCreated` y `onCategoryCreated` mandan push (FCM) a la pareja. |

**Modelo de datos (Firestore)**

```
users/{uid}                 displayName, email, coupleId, partnerUid, fcmTokens[]
invites/{code}              ownerUid, expiresAt          (solo Functions)
couples/{coupleId}          members[2]
  categories/{catId}        name, emoji, photoURL, ownerUid, entryCount, lastEntryAt, createdAt
    entries/{entryId}       note, photoURL, createdBy, createdAt
```

---

## Puesta en marcha

### 1. Crear el proyecto en Firebase (consola web)

1. Ve a <https://console.firebase.google.com> → **Agregar proyecto** (ej. `melita`).
2. **Cambia al plan Blaze** (pago por uso; con 2 personas es prácticamente gratis). Cloud Functions y
   los buckets nuevos de Storage lo requieren.
3. **Authentication** → *Comenzar* → habilita **Correo electrónico/contraseña**.
4. **Firestore Database** → *Crear base de datos* (modo producción, la región que prefieras).
5. **Storage** → *Comenzar*.
6. **Configuración del proyecto → General → Agregar app → iOS**
   - Bundle ID: `com.mera.melita` (o el que pongas en Xcode; deben coincidir).
   - Descarga **`GoogleService-Info.plist`** y ponlo en `Melita-iOS/Melita/` (al lado de la carpeta `App/`).
     Xcode lo detecta solo.

### 2. Notificaciones push (APNs)

Requiere cuenta de Apple Developer (99 USD/año) y un **iPhone real** (en el simulador no llegan pushes de FCM).

1. En <https://developer.apple.com/account/resources/authkeys/list> crea una **Key** con *Apple Push Notifications service (APNs)* y descarga el `.p8`.
2. En Firebase → Configuración del proyecto → **Cloud Messaging** → *Configuración de apps de Apple* → sube el `.p8` con tu **Key ID** y **Team ID**.

### 3. Desplegar el backend

Necesitas Node 22.

```bash
npm install -g firebase-tools
firebase login

cd Melita-Firebase
firebase use --add              # elige tu proyecto (reemplaza el placeholder de .firebaserc)
cd functions && npm install && cd ..

firebase deploy                 # reglas de Firestore + Storage + Cloud Functions
```

> La primera vez, el CLI te pedirá permiso para que las reglas de Storage lean Firestore
> (`firestore.get`): acepta.

### 4. Correr la app

1. Abre `Melita-iOS/Melita.xcodeproj` en **Xcode 16 o superior**. Espera a que descargue Firebase (Swift Package Manager).
2. Target **Melita → Signing & Capabilities** → elige tu **Team** (si cambias el Bundle ID, cámbialo también en Firebase).
3. Conecta tu iPhone y dale ▶︎.
4. Crea cuenta en tu iPhone, tu novia en el suyo, uno genera el código, el otro lo escribe. ¡Listo!

### Probar en local con emuladores (sin desplegar)

```bash
cp Melita-iOS/Config/emulators/GoogleService-Info.plist Melita-iOS/Melita/   # plist de prueba (proyecto demo-)
cd Melita-Firebase/functions && npm install && npm run emulators          # UI en http://localhost:4000
```

La app detecta sola el modo: con el plist de prueba (`PROJECT_ID` = `demo-…`) usa los emuladores;
con el plist real de tu proyecto se conecta a Firebase en producción. No hay que tocar código.
(Los pushes no funcionan con emuladores.)

---

## Ideas para seguir

- Abrir la categoría al tocar la notificación (los datos ya vienen en el payload: `coupleId`, `categoryId`).
- Permitir que la pareja también agregue registros a tus categorías (cambiar la regla de `entries` en `firestore.rules`).
- Gráficas por día/semana con Swift Charts.
- Iniciar sesión con Apple.
- Foto en la notificación (requiere una *Notification Service Extension*).
