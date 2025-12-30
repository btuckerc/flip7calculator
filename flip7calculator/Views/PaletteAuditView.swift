//
//  PaletteAuditView.swift
//  flip7calculator
//
//  A debug/preview view to audit all player palettes at different player counts.
//  Shows how colors look in tiles and charts, plus distance metrics.
//

import SwiftUI

struct PaletteAuditView: View {
    @State private var selectedPalette: PlayerPalette = .ocean
    @State private var playerCount: Int = 4
    @State private var showingMetrics = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Palette picker
                    palettePickerSection
                    
                    // Player count stepper
                    playerCountSection
                    
                    // Preview tiles
                    tilesPreviewSection
                    
                    // Color swatches (chart legend style)
                    swatchesSection
                    
                    // Reserved colors reference
                    reservedColorsSection
                    
                    // Metrics (collapsible)
                    metricsSection
                }
                .padding()
            }
            .navigationTitle("Palette Audit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Sections
    
    private var palettePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Palette")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PlayerPalette.allCases, id: \.rawValue) { palette in
                        Button {
                            selectedPalette = palette
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: palette.icon)
                                    .font(.system(size: 16))
                                Text(palette.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedPalette == palette ? Color.blue.opacity(0.15) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPalette == palette ? Color.blue : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Player Count")
                .font(.headline)
            
            HStack {
                ForEach(2...8, id: \.self) { count in
                    Button {
                        playerCount = count
                    } label: {
                        Text("\(count)")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(playerCount == count ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundStyle(playerCount == count ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var tilesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tiles Preview")
                .font(.headline)
            
            let colors = PlayerColorResolver.colors(count: playerCount, palette: selectedPalette)
            let columns = playerCount <= 4 ? 2 : (playerCount <= 6 ? 3 : 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                ForEach(0..<playerCount, id: \.self) { index in
                    AuditTilePreview(
                        playerNumber: index + 1,
                        color: colors[index],
                        isSelected: index == 0
                    )
                }
            }
            
            Text("First tile shown as selected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var swatchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chart Legend Swatches")
                .font(.headline)
            
            let colors = PlayerColorResolver.colors(count: playerCount, palette: selectedPalette)
            
            HStack(spacing: 12) {
                ForEach(0..<playerCount, id: \.self) { index in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(colors[index])
                            .frame(width: 24, height: 24)
                        Text("P\(index + 1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var reservedColorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reserved Action Colors")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(ReservedColors.bankGreen)
                        .frame(width: 32, height: 32)
                    Text("Bank")
                        .font(.caption)
                }
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(ReservedColors.bustRed)
                        .frame(width: 32, height: 32)
                    Text("Bust")
                        .font(.caption)
                }
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(ReservedColors.freezeCyan)
                        .frame(width: 32, height: 32)
                    Text("Freeze")
                        .font(.caption)
                }
                
                Spacer()
            }
            
            Text("Player colors should look distinct from these")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showingMetrics.toggle()
            } label: {
                HStack {
                    Text("Color Metrics")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showingMetrics ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showingMetrics {
                let colors = selectedPalette.colors
                let minSeparation = ColorDistance.minimumSeparation(colors)
                let issues = PlayerColorResolver.validatePalette(selectedPalette)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Overall metrics
                    HStack {
                        Text("Min player separation:")
                        Spacer()
                        Text(String(format: "%.3f", minSeparation))
                            .foregroundStyle(minSeparation >= ColorDistance.minimumPlayerSeparation ? .green : .red)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Required minimum:")
                        Spacer()
                        Text(String(format: "%.3f", ColorDistance.minimumPlayerSeparation))
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Per-color distances to reserved
                    Text("Distance to nearest reserved color:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(0..<colors.count, id: \.self) { index in
                        let distance = ColorDistance.distanceToNearestReserved(colors[index])
                        let isSafe = distance >= ColorDistance.minimumReservedDistance
                        
                        HStack {
                            Circle()
                                .fill(colors[index])
                                .frame(width: 16, height: 16)
                            Text("Color \(index + 1):")
                            Spacer()
                            Text(String(format: "%.3f", distance))
                                .foregroundStyle(isSafe ? .green : .red)
                        }
                        .font(.caption)
                    }
                    
                    // Validation issues
                    if !issues.isEmpty {
                        Divider()
                        Text("Issues:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                        
                        ForEach(issues, id: \.self) { issue in
                            Text("• \(issue)")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
}

// MARK: - Audit Tile Preview

private struct AuditTilePreview: View {
    let playerNumber: Int
    let color: Color
    let isSelected: Bool
    
    private var foregroundColor: Color {
        isSelected ? color.contrastingForeground : .primary
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Player \(playerNumber)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
            
            Text("42")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? color : color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? color.opacity(0) : color.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    PaletteAuditView()
}

