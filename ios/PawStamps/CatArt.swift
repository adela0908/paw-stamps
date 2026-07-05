import SwiftUI

/// The mascot: white blob cat with tiny pointy ears, dot eyes and a wavy mouth.
/// Drawn in a 140x120 design space and scaled to fit.
struct MascotView: View {
    var animated: Bool = true
    @State private var bounce = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / 140, geo.size.height / 120)
            ZStack {
                TailShape()
                    .stroke(Palette.ink, style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
                    .rotationEffect(.degrees(bounce ? 10 : 0), anchor: .bottomLeading)
                CatBodyView(scale: s)
                    .scaleEffect(x: bounce ? 1.03 : 1, y: bounce ? 0.94 : 1, anchor: .bottom)
            }
            .frame(width: 140 * s, height: 120 * s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .onAppear {
                guard animated else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
        }
        .aspectRatio(140.0 / 120.0, contentMode: .fit)
    }
}

private struct CatBodyView: View {
    let scale: CGFloat

    var body: some View {
        let s = scale
        ZStack {
            // ears
            EarShape(left: true).fill(Color.white)
            EarShape(left: true).stroke(Palette.ink, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
            EarShape(left: false).fill(Color.white)
            EarShape(left: false).stroke(Palette.ink, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
            // body blob
            Ellipse()
                .fill(Color.white)
                .frame(width: 104 * s, height: 92 * s)
                .position(x: 72 * s, y: 68 * s)
            Ellipse()
                .stroke(Palette.ink, lineWidth: 5 * s)
                .frame(width: 104 * s, height: 92 * s)
                .position(x: 72 * s, y: 68 * s)
            // eyes
            Ellipse().fill(Palette.ink)
                .frame(width: 8.4 * s, height: 12 * s)
                .position(x: 52 * s, y: 56 * s)
            Ellipse().fill(Palette.ink)
                .frame(width: 8.4 * s, height: 12 * s)
                .position(x: 92 * s, y: 56 * s)
            // wavy mouth
            MouthShape()
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 4.5 * s, lineCap: .round))
            // feet
            ForEach([54.0, 90.0], id: \.self) { x in
                Ellipse().fill(Color.white)
                    .frame(width: 24 * s, height: 13 * s)
                    .position(x: x * s, y: 112 * s)
                Ellipse().stroke(Palette.ink, lineWidth: 4.5 * s)
                    .frame(width: 24 * s, height: 13 * s)
                    .position(x: x * s, y: 112 * s)
            }
        }
        .frame(width: 140 * scale, height: 120 * scale)
    }
}

/// Shapes below are defined in the 140x120 design space; `path(in:)` rescales.
private func pt(_ x: CGFloat, _ y: CGFloat, _ rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + x / 140 * rect.width, y: rect.minY + y / 120 * rect.height)
}

private struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: pt(16, 98, rect))
        p.addQuadCurve(to: pt(6, 72, rect), control: pt(0, 90, rect))
        p.addQuadCurve(to: pt(17, 66, rect), control: pt(9, 63, rect))
        return p
    }
}

private struct EarShape: Shape {
    let left: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if left {
            p.move(to: pt(34, 40, rect))
            p.addLine(to: pt(42, 8, rect))
            p.addLine(to: pt(64, 26, rect))
        } else {
            p.move(to: pt(112, 40, rect))
            p.addLine(to: pt(104, 8, rect))
            p.addLine(to: pt(82, 26, rect))
        }
        p.closeSubpath()
        return p
    }
}

private struct MouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: pt(50, 72, rect))
        p.addQuadCurve(to: pt(71, 77, rect), control: pt(60, 84, rect))
        p.addQuadCurve(to: pt(92, 72, rect), control: pt(82, 84, rect))
        return p
    }
}

/// Red ink paw print used as the collected stamp.
struct PawPrint: View {
    var color: Color = Palette.red
    var rotation: Double = 0
    var opacity: Double = 0.92

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let u = w / 80
            ZStack {
                Ellipse().frame(width: 34 * u, height: 27 * u).position(x: 40 * u, y: 49 * u)
                Ellipse().frame(width: 14 * u, height: 16 * u)
                    .rotationEffect(.degrees(-18)).position(x: 21 * u, y: 31 * u)
                Ellipse().frame(width: 14 * u, height: 16 * u).position(x: 34 * u, y: 23 * u)
                Ellipse().frame(width: 14 * u, height: 16 * u).position(x: 47 * u, y: 23 * u)
                Ellipse().frame(width: 14 * u, height: 16 * u)
                    .rotationEffect(.degrees(18)).position(x: 59 * u, y: 31 * u)
            }
            .foregroundColor(color)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Big paw with a dashed ring, used for the slam overlay.
struct BigStamp: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.red, style: StrokeStyle(lineWidth: 8, dash: [20, 12]))
                .padding(6)
            PawPrint(opacity: 1)
                .padding(34)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
