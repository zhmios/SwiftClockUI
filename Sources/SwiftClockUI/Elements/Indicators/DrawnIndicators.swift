import SwiftUI

struct DrawnIndicators: View {
    @EnvironmentObject var viewModel: AnyIndicatorsViewModel
    
    var body: some View {
        ZStack {
            if viewModel.isHourIndicatorsShown {
                Hours()
            }
            if viewModel.isMinuteIndicatorsShown {
                Minutes()
            }
            DrawnNumbers()
        }
        .animation(.easeOut)
    }
}

private struct Hours: View {
    private static let widthRatio: CGFloat = 1/40
    private static let heightRatio: CGFloat = 1/20
    private static let marginRatio: CGFloat = 1/20
    @State private var animate: Bool = false
    
    var body: some View {
        ForEach(1...12, id: \.self) { hour in
            DrawnIndicator(draw: self.animate)
                .rotation(Angle(degrees: Double(hour) * .hourInDegree))
                .fill()
                .modifier(FrameProportional(widthRatio: Self.widthRatio, heightRatio: Self.heightRatio))
                .modifier(PositionInCircle(
                    angle: .degrees(Double(hour) * .hourInDegree),
                    marginRatio: Self.marginRatio
                ))
                .onAppear(perform: { self.animate = true })
        }
    }
}

private struct Minutes: View {
    @EnvironmentObject var viewModel: AnyIndicatorsViewModel
    private static let widthRatio: CGFloat = 1/50
    private static let heightRatio: CGFloat = 1/30
    private static let marginRatio: CGFloat = 1/30
    @State private var animate: Bool = false
    
    var body: some View {
        ForEach(1...60, id: \.self) { minute in
            Group {
                if self.isOverlapingHour(minute: minute) {
                    EmptyView()
                } else {
                    self.indicator(minute: minute)
                }
            }
        }
    }
    
    private func indicator(minute: Int) -> some View {
        Group {
            if self.isOverlapingHour(minute: minute) {
                EmptyView()
            } else {
                DrawnIndicator(draw: self.animate)
                    .rotation(Angle(degrees: Double(minute) * .minuteInDegree))
                    .fill()
                    .modifier(FrameProportional(widthRatio: Self.widthRatio, heightRatio: Self.heightRatio))
                    .modifier(PositionInCircle(
                        angle: .degrees(Double(minute) * .minuteInDegree),
                        marginRatio: Self.marginRatio
                    ))
                    .onAppear(perform: { self.animate = true })
            }
        }
    }
    
    private func isOverlapingHour(minute: Int) -> Bool {
        guard viewModel.isHourIndicatorsShown else { return false }
        return minute == 0 || minute % 5 == 0
    }
}

struct DrawnIndicator: Shape {
    private var drawStep: CGFloat
    private var controlRatios = DrawnControlRatios()
    
    init(draw: Bool) {
        self.drawStep = draw || Current.isAnimationDisabled ? 1 : 0
    }
    
    var animatableData: CGFloat {
        get { self.drawStep }
        set { self.drawStep = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width/2 * self.drawStep
        let bottomCenter = CGPoint(x: radius, y: rect.maxY * self.drawStep)
        let bottomRight = CGPoint(
            x: bottomCenter.x + radius/2,
            y: bottomCenter.y
        )
        let topCenter = CGPoint(x: radius, y: radius)
        let topLeft = CGPoint(
            x: topCenter.x - radius,
            y: topCenter.y
        )
        
        path.move(to: bottomRight)
        
        path.addArc(
            center: bottomCenter,
            radius: radius/2,
            startAngle: .zero,
            endAngle: .degrees(180),
            clockwise: false
        )
        
        let controlLeft = CGPoint(
            x: rect.maxX * self.controlRatios.leftX,
            y: rect.maxY * self.controlRatios.leftY
        )
        path.addQuadCurve(to: topLeft, control: controlLeft)
        
        path.addArc(
            center: topCenter,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .zero,
            clockwise: false
        )
        
        let controlRight = CGPoint(
            x: rect.maxX * self.controlRatios.rightX,
            y: rect.maxY * self.controlRatios.rightY
        )
        path.addQuadCurve(to: bottomRight, control: controlRight)
        
        return path
    }
}

struct DrawnNumbers: View {
    @EnvironmentObject var viewModel: AnyIndicatorsViewModel
    private static let hours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    private static let limitedHours = [12, 3, 6, 9]
    private static let marginRatio: CGFloat = 1/7
    private static let fontSizeRatio: CGFloat = 1/10
    
    var body: some View {
        ForEach(self.configurationHours, id: \.self) { hour in
            self.hourText(hour)
        }
    }
    
    private func hourText(_ hour: Int) -> some View {
        Text("\(hour)")
            .modifier(FontProportional(ratio: Self.fontSizeRatio))
            .rotationEffect(Current.randomAngle() ?? .zero, anchor: .center)
            .scaleEffect(Current.randomScale() ?? 1, anchor: .center)
            .modifier(PositionInCircle(
                angle: .degrees(Double(hour) * .hourInDegree), marginRatio: self.marginRatio
            ))
    }
    
    private var marginRatio: CGFloat {
        viewModel.isHourIndicatorsShown || viewModel.isMinuteIndicatorsShown
            ? Self.marginRatio
            : Self.marginRatio/2
    }
    
    private var configurationHours: [Int] {
        viewModel.isLimitedHoursShown ? Self.limitedHours : Self.hours
    }
}

#if DEBUG
struct DrawnIndicators_Previews: PreviewProvider {
    static var previews: some View {
        DrawnIndicators()
    }
}
#endif