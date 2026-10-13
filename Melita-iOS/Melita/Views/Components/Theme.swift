import SwiftUI

// MARK: - Colores

extension Color {
    /// Crea un color que cambia entre modo claro y oscuro.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Tokens de la identidad "Boletos de rifa".
enum Theme {
    /// Fondo general: gris lila frío (claro) o gris casi negro neutro (oscuro).
    static let ground = Color(light: 0xF3F1F6, dark: 0x121212)
    /// Superficies elevadas: campos, marcador, filas.
    static let surface = Color(light: 0xFFFFFF, dark: 0x1F1F21)
    static let ink = Color(light: 0x1E1A2B, dark: 0xF2F2F3)
    static let inkSecondary = Color(light: 0x6B6577, dark: 0xA1A1A6)
    /// Línea de perforación sobre superficies neutras.
    static let perforation = Color(light: 0xD6D1DE, dark: 0x38383A)
    /// Color de acción (tint). Bermellón del boleto.
    static let tint = Color(light: 0xD93A26, dark: 0xFF5B48)

    static let cornerRadius: CGFloat = 14
}

// MARK: - Stocks de boleto

/// Juego fijo y numerado de colores de boleto. Ninguna categoría inventa su color.
enum TicketStock: Int, CaseIterable, Identifiable {
    case bermellon, maiz, menta, pervinca, rosa, cielo

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .bermellon: "Bermellón"
        case .maiz: "Maíz"
        case .menta: "Menta"
        case .pervinca: "Pervinca"
        case .rosa: "Rosa"
        case .cielo: "Cielo"
        }
    }

    /// Color del papel (igual en claro y oscuro: es papel impreso).
    var paper: Color {
        switch self {
        case .bermellon: Color(hex: 0xD93A26)
        case .maiz: Color(hex: 0xF2A922)
        case .menta: Color(hex: 0x3DBE8E)
        case .pervinca: Color(hex: 0x5F5BD6)
        case .rosa: Color(hex: 0xF27BA8)
        case .cielo: Color(hex: 0x4FB3F0)
        }
    }

    /// Tinta que se imprime sobre el papel (contraste ≥ 4.5:1).
    var ink: Color {
        switch self {
        case .bermellon, .pervinca: .white
        default: Color(hex: 0x1E1A2B)
        }
    }
}

extension TrackerCategory {
    /// Stock guardado, o uno estable derivado del id para categorías anteriores.
    var ticketStock: TicketStock {
        if let stock, let value = TicketStock(rawValue: stock) { return value }
        let seed = (id ?? name).unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return TicketStock(rawValue: seed % TicketStock.allCases.count) ?? .bermellon
    }

    var touchedToday: Bool {
        guard let last = lastEntryAt?.dateValue() else { return false }
        return Calendar.current.isDateInToday(last)
    }
}

// MARK: - Tipografía

extension Font {
    /// Numerales de folio: Barlow Condensed ExtraBold, escala con Dynamic Type.
    static func folio(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("BarlowCondensed-ExtraBold", size: size, relativeTo: style)
    }
}

// MARK: - Forma de boleto

/// Rectángulo con esquinas continuas y dos muescas semicirculares donde empieza el talón.
struct TicketShape: Shape {
    enum Axis { case horizontal, vertical }

    /// `.vertical`: el talón está abajo (muescas a los lados). `.horizontal`: el talón está a la derecha.
    var axis: Axis = .vertical
    /// Distancia desde el borde inferior (o derecho) hasta la perforación.
    var stubLength: CGFloat
    var notchRadius: CGFloat = 8
    var cornerRadius: CGFloat = Theme.cornerRadius

    func path(in rect: CGRect) -> Path {
        let base = Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
        var notches = Path()
        let r = notchRadius
        switch axis {
        case .vertical:
            let y = rect.maxY - stubLength
            notches.addEllipse(in: CGRect(x: rect.minX - r, y: y - r, width: r * 2, height: r * 2))
            notches.addEllipse(in: CGRect(x: rect.maxX - r, y: y - r, width: r * 2, height: r * 2))
        case .horizontal:
            let x = rect.maxX - stubLength
            notches.addEllipse(in: CGRect(x: x - r, y: rect.minY - r, width: r * 2, height: r * 2))
            notches.addEllipse(in: CGRect(x: x - r, y: rect.maxY - r, width: r * 2, height: r * 2))
        }
        return base.subtracting(notches)
    }
}

/// Línea punteada de perforación.
struct Perforation: View {
    var axis: TicketShape.Axis = .vertical
    var color: Color

    var body: some View {
        Group {
            switch axis {
            case .vertical:
                Line(axis: .horizontal)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 7]))
                    .frame(height: 2)
            case .horizontal:
                Line(axis: .vertical)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 7]))
                    .frame(width: 2)
            }
        }
        .accessibilityHidden(true)
    }

    private struct Line: Shape {
        enum Axis { case horizontal, vertical }
        var axis: Axis
        func path(in rect: CGRect) -> Path {
            var p = Path()
            switch axis {
            case .horizontal:
                p.move(to: CGPoint(x: rect.minX + 10, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.midY))
            case .vertical:
                p.move(to: CGPoint(x: rect.midX, y: rect.minY + 10))
                p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 10))
            }
            return p
        }
    }
}

/// Sello estampado sobre el boleto (HOY, NUEVO…).
struct Stamp: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.heavy))
            .tracking(1.2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(color, lineWidth: 1.5))
            .rotationEffect(.degrees(6))
    }
}

// MARK: - Marca

/// El logo: un boleto con talón de maíz y un corazón picado, inclinado -10°.
struct MelitaMark: View {
    var bodyPaper = TicketStock.bermellon.paper
    var stubPaper = TicketStock.maiz.paper

    var body: some View {
        Canvas { context, size in
            // Caja de diseño: 800 × 660, centrada.
            let scale = min(size.width / 800, size.height / 660)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            context.rotate(by: .degrees(-10))
            context.clip(to: Self.ticketPath)
            context.fill(Path(CGRect(x: -360, y: -220, width: 510, height: 440)), with: .color(bodyPaper))
            context.fill(Path(CGRect(x: 150, y: -220, width: 210, height: 440)), with: .color(stubPaper))
        }
        .aspectRatio(800 / 660, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// Boleto 720 × 440 menos las muescas, la perforación y el corazón.
    private static let ticketPath: Path = {
        let ticket = Path(roundedRect: CGRect(x: -360, y: -220, width: 720, height: 440), cornerRadius: 52, style: .continuous)
        var holes = Path()
        holes.addEllipse(in: CGRect(x: 150 - 44, y: -220 - 44, width: 88, height: 88))
        holes.addEllipse(in: CGRect(x: 150 - 44, y: 220 - 44, width: 88, height: 88))
        for y in stride(from: -150, through: 150, by: 37) {
            holes.addEllipse(in: CGRect(x: 150 - 9, y: CGFloat(y) - 9, width: 18, height: 18))
        }
        holes.addPath(heart.applying(CGAffineTransform(translationX: -110, y: 12)))
        return ticket.subtracting(holes)
    }()

    private static let heart: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 70))
        p.addCurve(to: CGPoint(x: -110, y: -50), control1: CGPoint(x: -60, y: 30), control2: CGPoint(x: -110, y: -5))
        p.addCurve(to: CGPoint(x: -50, y: -110), control1: CGPoint(x: -110, y: -85), control2: CGPoint(x: -82, y: -110))
        p.addCurve(to: CGPoint(x: 0, y: -80), control1: CGPoint(x: -28, y: -110), control2: CGPoint(x: -10, y: -98))
        p.addCurve(to: CGPoint(x: 50, y: -110), control1: CGPoint(x: 10, y: -98), control2: CGPoint(x: 28, y: -110))
        p.addCurve(to: CGPoint(x: 110, y: -50), control1: CGPoint(x: 82, y: -110), control2: CGPoint(x: 110, y: -85))
        p.addCurve(to: CGPoint(x: 0, y: 70), control1: CGPoint(x: 110, y: -5), control2: CGPoint(x: 60, y: 30))
        p.closeSubpath()
        return p
    }()
}

/// Logotipo completo: marca + "melita".
struct MelitaLogo: View {
    var markHeight: CGFloat = 44
    var color: Color = Theme.ink

    var body: some View {
        HStack(spacing: markHeight * 0.18) {
            MelitaMark().frame(height: markHeight)
            Text("melita")
                .font(.folio(markHeight * 1.05, relativeTo: .largeTitle))
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Melita")
    }
}
