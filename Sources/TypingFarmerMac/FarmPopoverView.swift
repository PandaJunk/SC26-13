import AppKit
import SwiftUI
import TypingFarmerCore
import TypingFarmerMacSupport

struct FarmGameWindowView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        ZStack {
            ArtImage(name: "farm_background", contentMode: .fill)
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.06),
                            .clear,
                            .black.opacity(0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack(spacing: 12) {
                GameHUDView(model: model)

                VStack(spacing: 12) {
                    KeyboardFarmView(model: model)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    CropDockView(model: model)
                        .frame(height: 90)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 1040, minHeight: 680)
    }
}

struct FarmControlPanelView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        ZStack {
            ArtImage(name: "farm_background", contentMode: .fill)
                .overlay(Color(red: 0.42, green: 0.31, blue: 0.10).opacity(0.42))
                .ignoresSafeArea()

            SidePanelView(model: model)
                .padding(12)
        }
        .frame(minWidth: 320, minHeight: 560)
    }
}

private struct GameHUDView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("指尖农场")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("键盘播种，成熟收获")
                    .font(.caption.weight(.heavy))
                    .opacity(0.86)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
            .frame(minWidth: 150, alignment: .leading)

            Spacer(minLength: 6)

            HUDStatPill(title: "今日输入", value: "\(model.todayStats.totalInput)")
            HUDStatPill(title: "专注", value: "\(model.todayStats.focusSessions)")
            PermissionPill(status: model.permissionStatus)
            CoinPill(value: model.state.coins)

            GameIconButton(title: "打开农场面板", systemName: "slider.horizontal.3") {
                NotificationCenter.default.post(name: .typingFarmerShowControlPanel, object: nil)
            }

            GameIconButton(title: model.windowSettings.isAlwaysOnTop ? "取消置顶" : "窗口置顶", systemName: model.windowSettings.isAlwaysOnTop ? "pin.fill" : "pin") {
                model.setAlwaysOnTop(!model.windowSettings.isAlwaysOnTop)
            }

            GameIconButton(title: "隐藏窗口", systemName: "xmark") {
                NotificationCenter.default.post(name: .typingFarmerHideWindow, object: nil)
            }
        }
        .padding(.leading, 22)
        .padding(.trailing, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(Color(red: 0.13, green: 0.19, blue: 0.08).opacity(0.58))
                .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
        )
        .overlay(Capsule().stroke(.white.opacity(0.24), lineWidth: 1))
    }
}

private struct HUDStatPill: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: 17, weight: .heavy, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(title)
                .font(.caption2.weight(.bold))
                .opacity(0.78)
        }
        .foregroundStyle(.white)
        .frame(width: 78)
        .padding(.vertical, 6)
        .background(HUDMaterialShape())
    }
}

private struct PermissionPill: View {
    var status: InputMonitor.PermissionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status == .authorized ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(status.title)
                .font(.caption.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .foregroundStyle(.white)
        .frame(width: 92)
        .padding(.vertical, 10)
        .background(HUDMaterialShape())
    }
}

private struct CoinPill: View {
    var value: Int
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 7) {
            ArtImage(name: "coin", contentMode: .fit)
                .frame(width: 28, height: 28)
            Text("\(value)")
                .font(.system(size: 21, weight: .heavy, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.white)
        .padding(.leading, 9)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 0.50, green: 0.29, blue: 0.07).opacity(0.88))
                .shadow(color: .black.opacity(0.26), radius: 7, y: 3)
        )
        .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 1))
        .scaleEffect(isPulsing ? 1.08 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.62), value: isPulsing)
        .onChange(of: value) { _, _ in
            isPulsing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                isPulsing = false
            }
        }
    }
}

private struct GameIconButton: View {
    var title: String
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .black))
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
                .background(Circle().fill(Color.black.opacity(0.34)))
                .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

private struct KeyboardFarmView: View {
    @ObservedObject var model: AppViewModel

    private let rowSpacing: CGFloat = 12
    private let keySpacing: CGFloat = 8
    private let contentPadding: CGFloat = 14
    private let petLaneHeight: CGFloat = 52

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(1, geometry.size.width - contentPadding * 2)
            let contentHeight = max(1, geometry.size.height - contentPadding * 2)
            let keyAreaHeight = max(1, contentHeight - petLaneHeight)
            let rowCandidates = MacKeyboardLayout.rows.enumerated().map { index, row in
                let rowUnits = row.reduce(0) { $0 + keyWidthUnits(for: $1) } + rowIndentUnits(for: index)
                let rowSpacingWidth = CGFloat(row.count - 1) * keySpacing
                return (contentWidth - rowSpacingWidth) / rowUnits
            }
            let unitWidth = max(24, rowCandidates.min() ?? 34)
            let keyHeight = max(42, min(76, (keyAreaHeight - rowSpacing * 4 - 24) / 5))
            let contentSize = CGSize(width: contentWidth, height: contentHeight)
            let spritePlots = farmSpritePlots(
                unitWidth: unitWidth,
                keyHeight: keyHeight,
                keyAreaHeight: keyAreaHeight,
                contentSize: contentSize
            )

            ZStack {
                VStack(spacing: rowSpacing) {
                    ForEach(Array(MacKeyboardLayout.rows.enumerated()), id: \.offset) { index, row in
                        HStack(spacing: keySpacing) {
                            ForEach(row) { key in
                                let plot = model.state.keyPlots.first { $0.keyCode == key.keyCode }
                                KeyFarmTile(
                                    plot: plot,
                                    crop: plot.flatMap { model.cropsByID[$0.cropID] },
                                    selectedCropID: model.state.selectedCropID,
                                    onHarvest: {
                                        if let plot {
                                            model.harvest(keyID: plot.keyID)
                                        }
                                    },
                                    onPlant: {
                                        if let plot {
                                            model.plant(cropID: model.state.selectedCropID, in: plot.keyID)
                                        }
                                    }
                                )
                                .frame(width: unitWidth * keyWidthUnits(for: key), height: keyHeight)
                            }
                        }
                        .padding(.leading, rowIndent(for: index, unitWidth: unitWidth))
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(height: keyAreaHeight, alignment: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                FarmSpriteLayer(
                    plots: spritePlots,
                    pets: spritePets,
                    harvestEvents: model.harvestAnimationEvents,
                    onPetCollect: { petID, keyID in
                        model.completePetHarvest(petID: petID, keyID: keyID)
                    }
                )
                .frame(width: contentWidth, height: contentHeight)
                .allowsHitTesting(false)

                PetLanePreviewView(pets: spritePets)
                    .frame(width: contentWidth, height: contentHeight, alignment: .bottomLeading)
                    .allowsHitTesting(false)
            }
            .frame(width: contentWidth, height: contentHeight)
            .padding(contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(minHeight: 390)
    }

    private var spritePets: [FarmSpritePet] {
        model.state.adoptedPets.compactMap { pet in
            guard let definition = model.petDefinition(for: pet) else {
                return nil
            }
            return FarmSpritePet(
                id: pet.id,
                species: definition.species,
                assetPrefix: definition.assetPrefix
            )
        }
    }

    private func rowIndent(for index: Int, unitWidth: CGFloat) -> CGFloat {
        unitWidth * rowIndentUnits(for: index)
    }

    private func rowIndentUnits(for index: Int) -> CGFloat {
        switch index {
        case 1:
            return 0.24
        case 2:
            return 0.42
        case 3:
            return 0.78
        default:
            return 0
        }
    }

    private func keyWidthUnits(for key: KeyboardKeyDefinition) -> CGFloat {
        if key.keyCode == 49 {
            return 4.8
        }
        return CGFloat(key.widthUnits)
    }

    private func farmSpritePlots(
        unitWidth: CGFloat,
        keyHeight: CGFloat,
        keyAreaHeight: CGFloat,
        contentSize: CGSize
    ) -> [FarmSpritePlot] {
        let definitions = model.cropsByID
        let now = Date()
        let totalHeight = CGFloat(MacKeyboardLayout.rows.count) * keyHeight + CGFloat(MacKeyboardLayout.rows.count - 1) * rowSpacing
        let startY = max(0, (keyAreaHeight - totalHeight) / 2)

        return MacKeyboardLayout.rows.enumerated().flatMap { rowIndex, row in
            let rowIndent = rowIndent(for: rowIndex, unitWidth: unitWidth)
            let rowWidth = rowIndent
                + row.reduce(0) { $0 + keyWidthUnits(for: $1) * unitWidth }
                + CGFloat(row.count - 1) * keySpacing
            var x = max(0, (contentSize.width - rowWidth) / 2) + rowIndent
            let y = startY + CGFloat(rowIndex) * (keyHeight + rowSpacing)

            return row.compactMap { key -> FarmSpritePlot? in
                let width = keyWidthUnits(for: key) * unitWidth
                defer {
                    x += width + keySpacing
                }

                guard let plot = model.state.keyPlots.first(where: { $0.keyCode == key.keyCode }) else {
                    return nil
                }
                let wasRecentlyHit = plot.lastHitAt.map { now.timeIntervalSince($0) < 0.65 } ?? false
                return FarmSpritePlot(
                    keyID: plot.keyID,
                    rect: CGRect(x: x, y: y, width: width, height: keyHeight),
                    isMature: plot.isMature(using: definitions),
                    wasRecentlyHit: wasRecentlyHit,
                    soilStage: soilStage(for: plot, crop: definitions[plot.cropID])
                )
            }
        }
    }

    private func soilStage(for plot: KeyPlotState, crop: CropDefinition?) -> Int {
        guard let crop else {
            return 1
        }
        let progress = min(1, Double(plot.progress) / Double(crop.growRequirement))
        switch progress {
        case ...0:
            return 1
        case ..<0.34:
            return 2
        case ..<0.72:
            return 3
        default:
            return 4
        }
    }
}

private struct KeyFarmTile: View {
    var plot: KeyPlotState?
    var crop: CropDefinition?
    var selectedCropID: String
    var onHarvest: () -> Void
    var onPlant: () -> Void

    private var progress: Double {
        guard let plot, let crop else {
            return 0
        }
        return min(1, Double(plot.progress) / Double(crop.growRequirement))
    }

    private var isMature: Bool {
        guard let plot, let crop else {
            return false
        }
        return plot.progress >= crop.growRequirement
    }

    private var wasRecentlyHit: Bool {
        guard let lastHitAt = plot?.lastHitAt else {
            return false
        }
        return Date().timeIntervalSince(lastHitAt) < 0.65
    }

    var body: some View {
        Button {
            if isMature {
                onHarvest()
            } else {
                onPlant()
            }
        } label: {
            GeometryReader { geometry in
                let tileSize = geometry.size
                let soilAssetName = keySoilAssetName(for: tileSize)
                let visualScale = soilVisualScale(for: tileSize)
                let visualSize = CGSize(width: tileSize.width * visualScale, height: tileSize.height * visualScale)
                ZStack {
                    Ellipse()
                        .fill(.black.opacity(0.22))
                        .frame(width: visualSize.width * 0.86, height: max(10, visualSize.height * 0.22))
                        .offset(y: tileSize.height * 0.40)
                        .blur(radius: 4)

                    ArtImage(name: soilAssetName, contentMode: .fit)
                        .frame(width: visualSize.width, height: visualSize.height)
                        .opacity(0.98)
                        .saturation(isMature ? 1.12 : 0.96 + progress * 0.14)
                        .brightness(isMature ? 0.025 : 0)
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 2)
                        .overlay(
                            cropGroundOverlay
                                .mask(
                                    ArtImage(name: soilAssetName, contentMode: .fit)
                                        .frame(width: visualSize.width, height: visualSize.height)
                                )
                        )

                    cropImage(in: geometry.size)

                    VStack {
                        HStack {
                            Text(plot?.keyLabel ?? "?")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.34)))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                            Spacer(minLength: 0)
                        }

                        Spacer(minLength: 0)

                        if isMature {
                            HStack {
                                Spacer(minLength: 0)
                                MatureCoinIcon()
                            }
                        }

                        ProgressBar(progress: progress, isMature: isMature)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, max(4, tileSize.height * 0.08))
                    .padding(.bottom, max(7, tileSize.height * 0.12))

                    if isMature || wasRecentlyHit {
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(tileStrokeColor, lineWidth: tileStrokeWidth)
                            .frame(width: visualSize.width * 0.93, height: visualSize.height * 0.72)
                            .offset(y: visualSize.height * 0.03)
                            .shadow(color: tileGlowColor, radius: isMature ? 12 : 8)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(isMature ? "点击收获" : "点击改种当前作物")
    }

    private func cropImage(in size: CGSize) -> some View {
        let cropWidth = min(max(24, size.width * cropWidthRatio), max(30, size.height * 0.92))
        return ArtImage(name: cropAssetName, contentMode: .fit)
            .frame(width: cropWidth, height: max(28, size.height * cropHeightRatio))
            .opacity(cropOpacity)
            .scaleEffect(isMature ? 1.08 : 0.82 + progress * 0.24)
            .offset(y: isMature ? -8 : -2 - progress * 7)
            .shadow(color: .black.opacity(0.24), radius: 2.5, x: 0, y: 4)
            .shadow(color: isMature ? .yellow.opacity(0.55) : .black.opacity(0.12), radius: isMature ? 8 : 3, y: 2)
            .animation(.spring(response: 0.24, dampingFraction: 0.70), value: progress)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isMature)
    }

    private var cropWidthRatio: CGFloat {
        isMature ? 0.92 : 0.78
    }

    private var cropHeightRatio: CGFloat {
        isMature ? 0.74 : 0.66
    }

    private var cropOpacity: Double {
        isMature ? 1 : 0.72 + progress * 0.24
    }

    private func soilVisualScale(for size: CGSize) -> CGFloat {
        let aspect = size.width / max(1, size.height)
        switch aspect {
        case ..<1.28:
            return 1.22
        case ..<1.85:
            return 1.16
        case ..<3.2:
            return 1.11
        default:
            return 1.06
        }
    }

    private var cropGroundOverlay: some View {
        LinearGradient(
            colors: [
                cropGroundColor.opacity(0.05 + progress * 0.08),
                cropGroundColor.opacity(0.11 + progress * 0.13),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.softLight)
    }

    private var cropGroundColor: Color {
        switch crop?.id {
        case "wheat":
            return Color(red: 0.95, green: 0.72, blue: 0.22)
        case "tomato":
            return Color(red: 0.30, green: 0.72, blue: 0.32)
        case "corn":
            return Color(red: 0.78, green: 0.88, blue: 0.24)
        case "strawberry":
            return Color(red: 0.90, green: 0.28, blue: 0.36)
        default:
            return Color(red: 0.55, green: 0.72, blue: 0.34)
        }
    }

    private var tileStrokeColor: Color {
        if isMature {
            return Color(red: 1.0, green: 0.78, blue: 0.18)
        }
        if wasRecentlyHit {
            return Color(red: 0.70, green: 1.0, blue: 0.42)
        }
        return Color(red: 0.96, green: 0.78, blue: 0.38).opacity(0.28)
    }

    private var tileStrokeWidth: CGFloat {
        isMature ? 3 : wasRecentlyHit ? 2.5 : 1
    }

    private var tileGlowColor: Color {
        if isMature {
            return .yellow.opacity(0.68)
        }
        if wasRecentlyHit {
            return Color(red: 0.62, green: 1.0, blue: 0.36).opacity(0.60)
        }
        return .clear
    }

    private var cropAssetName: String {
        guard let crop else {
            return "\(selectedCropID)_stage_1"
        }
        let stage = max(1, min(crop.stageCount, Int(ceil(progress * Double(crop.stageCount)))))
        return "\(crop.id)_stage_\(stage)"
    }

    private func keySoilAssetName(for size: CGSize) -> String {
        let stage = soilStage
        let aspect = size.width / max(1, size.height)
        switch aspect {
        case ..<1.28:
            return "key_soil_stage_\(stage)"
        case ..<1.85:
            return "key_soil_stage_\(stage)_wide_1_5"
        case ..<3.2:
            return "key_soil_stage_\(stage)_wide_2_2"
        default:
            return "key_soil_stage_\(stage)_wide_4_8"
        }
    }

    private var soilStage: Int {
        switch progress {
        case ...0:
            return 1
        case ..<0.34:
            return 2
        case ..<0.72:
            return 3
        default:
            return 4
        }
    }
}

private struct PetLanePreviewView: View {
    var pets: [FarmSpritePet]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(pets.prefix(8).enumerated()), id: \.element.id) { index, pet in
                ArtImage(name: "\(pet.assetPrefix)_idle", contentMode: .fit)
                    .frame(width: petSize(for: index), height: petSize(for: index))
                    .offset(y: CGFloat(index % 3) * -3)
                    .shadow(color: .black.opacity(0.20), radius: 3, y: 2)
            }
        }
        .padding(.leading, 42)
        .padding(.bottom, 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private func petSize(for index: Int) -> CGFloat {
        max(44, 58 - CGFloat(min(index, 4)) * 2.5)
    }
}

private struct MatureCoinIcon: View {
    var body: some View {
        ArtImage(name: "coin", contentMode: .fit)
            .frame(width: 27, height: 27)
            .padding(5)
            .background(Circle().fill(Color(red: 0.48, green: 0.27, blue: 0.03).opacity(0.72)))
            .overlay(Circle().stroke(Color(red: 1.0, green: 0.86, blue: 0.28).opacity(0.82), lineWidth: 1.5))
            .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.16).opacity(0.62), radius: 8)
            .shadow(color: .black.opacity(0.30), radius: 4, y: 2)
    }
}

private struct ProgressBar: View {
    var progress: Double
    var isMature: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.black.opacity(0.24))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isMature
                                ? [Color(red: 1.0, green: 0.84, blue: 0.20), Color(red: 0.96, green: 0.54, blue: 0.08)]
                                : [Color(red: 0.48, green: 0.94, blue: 0.32), Color(red: 0.19, green: 0.64, blue: 0.21)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, geometry.size.width * progress))
            }
        }
        .frame(height: 4)
    }
}

private struct CropDockView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 2) {
                Text("种子袋")
                    .font(.headline.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                if let selected = model.selectedCrop {
                    Text("已装备 \(selected.displayName)")
                        .font(.caption2.weight(.heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            .frame(width: 92, alignment: .leading)
            .layoutPriority(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.crops) { crop in
                        CropDockButton(
                            crop: crop,
                            isSelected: model.state.selectedCropID == crop.id,
                            isUnlocked: model.state.unlockedCropIDs.contains(crop.id),
                            coinCount: model.state.coins,
                            onSelect: { model.selectCrop(id: crop.id) },
                            onUnlock: { model.unlockCrop(id: crop.id) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.13, green: 0.09, blue: 0.03).opacity(0.74))
                .shadow(color: .black.opacity(0.18), radius: 9, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.20), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CropDockButton: View {
    var crop: CropDefinition
    var isSelected: Bool
    var isUnlocked: Bool
    var coinCount: Int
    var onSelect: () -> Void
    var onUnlock: () -> Void

    var body: some View {
        Button {
            if isUnlocked {
                onSelect()
            } else {
                onUnlock()
            }
        } label: {
            HStack(spacing: 7) {
                ArtImage(name: "\(crop.id)_stage_4", contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .opacity(isUnlocked ? 1 : 0.42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(crop.displayName)
                        .font(.caption.weight(.heavy))
                        .lineLimit(1)
                    Text(detailText)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? Color(red: 0.22, green: 0.12, blue: 0.03) : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(width: 136, height: 62)
            .background(buttonBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .white.opacity(0.86) : .white.opacity(0.18), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? .yellow.opacity(0.30) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked && coinCount < crop.unlockPrice)
        .opacity(!isUnlocked && coinCount < crop.unlockPrice ? 0.58 : 1)
        .help(isUnlocked ? "选择\(crop.displayName)" : "解锁\(crop.displayName)")
    }

    private var detailText: String {
        if isUnlocked {
            return "卖 \(crop.sellPrice) 需 \(crop.growRequirement)"
        }
        return coinCount >= crop.unlockPrice ? "可买 \(crop.unlockPrice)" : "锁定 \(crop.unlockPrice)"
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundFill)
    }

    private var backgroundFill: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.80, blue: 0.25), Color(red: 0.88, green: 0.60, blue: 0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color.white.opacity(isUnlocked ? 0.18 : 0.08),
                Color.black.opacity(isUnlocked ? 0.03 : 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct SidePanelView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                StatsPanel(stats: model.todayStats)
                ShopPanel(model: model)
                PetPanel(model: model)
                FocusPanel(model: model)
                SettingsPanel(model: model)
            }
            .padding(11)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.93, blue: 0.70).opacity(0.78),
                            Color(red: 0.87, green: 0.74, blue: 0.44).opacity(0.84)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.52, green: 0.34, blue: 0.12).opacity(0.22), lineWidth: 1))
    }
}

private struct StatsPanel: View {
    var stats: DailyStats

    var body: some View {
        GamePanel(title: "今日农场") {
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("\(stats.totalInput)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text("次耕作")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    StatBlock(title: "键盘", value: stats.keyboardCount)
                    StatBlock(title: "鼠标", value: stats.mouseCount)
                    StatBlock(title: "专注", value: stats.focusSessions)
                }
            }
        }
    }
}

private struct StatBlock: View {
    var title: String
    var value: Int

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color(red: 1.0, green: 0.82, blue: 0.38).opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct ShopPanel: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        GamePanel(title: "作物订单") {
            VStack(spacing: 7) {
                ForEach(displayCrops) { crop in
                    CropOrderRow(
                        crop: crop,
                        isUnlocked: model.state.unlockedCropIDs.contains(crop.id),
                        canUnlock: model.state.coins >= crop.unlockPrice,
                        isSelected: model.state.selectedCropID == crop.id,
                        onPrimaryAction: {
                            if model.state.unlockedCropIDs.contains(crop.id) {
                                model.selectCrop(id: crop.id)
                            } else {
                                model.unlockCrop(id: crop.id)
                            }
                        }
                    )
                }

                if model.lockedCrops.isEmpty {
                    Text("已解锁全部作物")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
        }
    }

    private var displayCrops: [CropDefinition] {
        let nextLocked = Array(model.lockedCrops.prefix(2))
        if nextLocked.isEmpty {
            return Array(model.unlockedCrops.suffix(2))
        }
        return nextLocked
    }
}

private struct CropOrderRow: View {
    var crop: CropDefinition
    var isUnlocked: Bool
    var canUnlock: Bool
    var isSelected: Bool
    var onPrimaryAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ArtImage(name: "\(crop.id)_stage_4", contentMode: .fit)
                .frame(width: 42, height: 42)
                .opacity(isUnlocked || canUnlock ? 1 : 0.45)

            VStack(alignment: .leading, spacing: 1) {
                Text(crop.displayName)
                    .font(.subheadline.weight(.heavy))
                    .lineLimit(1)
                Text(isUnlocked ? "成熟 +\(crop.sellPrice)" : "解锁 +\(crop.sellPrice)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 4)

            Button {
                onPrimaryAction()
            } label: {
                HStack(spacing: 3) {
                    if isUnlocked {
                        Text(isSelected ? "已装备" : "装备")
                    } else {
                        ArtImage(name: "coin", contentMode: .fit)
                            .frame(width: 14, height: 14)
                        Text("\(crop.unlockPrice)")
                    }
                }
                .font(.caption.weight(.heavy).monospacedDigit())
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
            .buttonStyle(GameSmallButtonStyle(isProminent: isUnlocked ? !isSelected : canUnlock))
            .disabled((!isUnlocked && !canUnlock) || isSelected)
        }
        .padding(7)
        .background(Color.white.opacity(isSelected ? 0.46 : 0.28))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isSelected ? Color(red: 0.98, green: 0.72, blue: 0.20).opacity(0.75) : .white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct PetPanel: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        GamePanel(title: "宠物屋") {
            VStack(spacing: 8) {
                HStack {
                    Text("已领养 \(model.state.adoptedPets.count) 只")
                        .font(.caption.weight(.heavy))
                    Spacer(minLength: 0)
                    Text("自动收获")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(model.state.adoptedPets.enumerated()), id: \.element.id) { index, pet in
                            if let definition = model.petDefinition(for: pet) {
                                AdoptedPetBadge(definition: definition, index: index)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
                .frame(height: 58)

                ForEach(model.petDefinitions) { definition in
                    PetAdoptionRow(
                        definition: definition,
                        ownedCount: model.state.adoptedPets.filter { $0.definitionID == definition.id }.count,
                        canAdopt: model.state.coins >= definition.adoptionPrice,
                        onAdopt: { model.adoptPet(definitionID: definition.id) }
                    )
                }
            }
        }
    }
}

private struct AdoptedPetBadge: View {
    var definition: PetDefinition
    var index: Int

    var body: some View {
        VStack(spacing: 2) {
            ArtImage(name: "\(definition.assetPrefix)_idle", contentMode: .fit)
                .frame(width: 42, height: 42)
            Text("\(definition.species.displayName) \(index + 1)")
                .font(.caption2.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(width: 68, height: 56)
        .background(Color.white.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.16), lineWidth: 1))
    }
}

private struct PetAdoptionRow: View {
    var definition: PetDefinition
    var ownedCount: Int
    var canAdopt: Bool
    var onAdopt: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ArtImage(name: "\(definition.assetPrefix)_idle", contentMode: .fit)
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(definition.displayName)
                    .font(.subheadline.weight(.heavy))
                    .lineLimit(1)
                Text("已拥有 \(ownedCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button {
                onAdopt()
            } label: {
                HStack(spacing: 3) {
                    ArtImage(name: "coin", contentMode: .fit)
                        .frame(width: 14, height: 14)
                    Text("\(definition.adoptionPrice)")
                }
                .font(.caption.weight(.heavy).monospacedDigit())
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
            .buttonStyle(GameSmallButtonStyle(isProminent: canAdopt))
            .disabled(!canAdopt)
            .help("领养\(definition.displayName)")
        }
        .padding(7)
        .background(Color.white.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct FocusPanel: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        GamePanel(title: "番茄钟") {
            VStack(spacing: 8) {
                Text(model.pomodoro.formattedRemainingTime)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                Stepper("\(model.pomodoro.durationMinutes) 分钟", value: durationBinding, in: 1...180)
                    .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    Button(model.pomodoro.isRunning ? "暂停" : "开始") {
                        if model.pomodoro.isRunning {
                            model.pausePomodoro()
                        } else {
                            model.startPomodoro()
                        }
                    }
                    .buttonStyle(GameSmallButtonStyle(isProminent: true))

                    Button("重置") {
                        model.resetPomodoro()
                    }
                    .buttonStyle(GameSmallButtonStyle(isProminent: false))
                }
            }
        }
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { model.pomodoro.durationMinutes },
            set: { model.setPomodoroDuration($0) }
        )
    }
}

private struct SettingsPanel: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        GamePanel(title: "工具棚") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("窗口置顶", isOn: alwaysOnTopBinding)
                    .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    Button("请求权限") {
                        model.requestAccessibilityPermission()
                    }
                    .buttonStyle(GameSmallButtonStyle(isProminent: model.permissionStatus != .authorized))

                    Button("刷新") {
                        model.refreshPermission()
                    }
                    .buttonStyle(GameSmallButtonStyle(isProminent: false))
                }

                HStack(spacing: 8) {
                    Button("隐藏") {
                        NotificationCenter.default.post(name: .typingFarmerHideWindow, object: nil)
                    }
                    .buttonStyle(GameSmallButtonStyle(isProminent: false))

                    Button("退出") {
                        model.quit()
                    }
                    .buttonStyle(GameSmallButtonStyle(isProminent: false))
                }

                Button("重置农场", role: .destructive) {
                    model.resetFarm()
                }
                .buttonStyle(GameSmallButtonStyle(isProminent: false))

                if let error = model.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var alwaysOnTopBinding: Binding<Bool> {
        Binding(
            get: { model.windowSettings.isAlwaysOnTop },
            set: { model.setAlwaysOnTop($0) }
        )
    }
}

private struct GamePanel<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Color(red: 0.30, green: 0.17, blue: 0.05))
            content
        }
        .padding(10)
        .background(Color.white.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.54, green: 0.35, blue: 0.12).opacity(0.16), lineWidth: 1))
    }
}

private struct HUDMaterialShape: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(red: 0.12, green: 0.22, blue: 0.08).opacity(0.58))
            .shadow(color: .black.opacity(0.16), radius: 7, y: 3)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.22), lineWidth: 1))
    }
}

private struct GameSmallButtonStyle: ButtonStyle {
    var isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.heavy))
            .foregroundStyle(isProminent ? .white : Color(red: 0.28, green: 0.16, blue: 0.05))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .frame(minHeight: 26)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isProminent ? Color(red: 0.31, green: 0.62, blue: 0.22) : Color.white.opacity(0.46))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isProminent ? .white.opacity(0.3) : Color(red: 0.54, green: 0.35, blue: 0.12).opacity(0.22), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct ArtImage: View {
    enum ContentMode {
        case fit
        case fill
    }

    var name: String
    var contentMode: ContentMode

    @ViewBuilder
    var body: some View {
        if let image = loadImage(named: name) {
            switch contentMode {
            case .fit:
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .fill:
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.58, green: 0.75, blue: 0.35), Color(red: 0.33, green: 0.53, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func loadImage(named name: String) -> NSImage? {
        let url = Bundle.module.url(forResource: name, withExtension: "png")
            ?? Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Art")
        guard let url else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

extension Notification.Name {
    static let typingFarmerHideWindow = Notification.Name("typingFarmerHideWindow")
}
