//
//  PlayersEditorCard.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/30/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Player Name Row Model

struct PlayerNameRow: Identifiable {
    let id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String = "") {
        self.id = id
        self.name = name
    }
}

// MARK: - Players Editor Card

/// A reusable card component for editing a list of players.
/// Includes inline Edit/Done toggle, drag-to-reorder, swipe-to-delete, and add player functionality.
struct PlayersEditorCard: View {
    @Binding var playerRows: [PlayerNameRow]
    let focusCoordinator: FocusCoordinator
    let onPersist: () -> Void
    var onReset: (() -> Void)? = nil
    var showsPlayerSummary = true
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var draggedRowId: UUID?
    @State private var isEditMode = false

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var raisedSurfaceColor: Color {
        DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
    }

    private var canEditPlayers: Bool {
        playerRows.count > 2
    }

    private var canAddPlayer: Bool {
        playerRows.count < 8
    }

    private var canResetPlayers: Bool {
        onReset != nil && (playerRows.count > 2 || playerRows.contains { !$0.name.isEmpty })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showsPlayerSummary {
                HStack {
                    Text("Players")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    if canEditPlayers {
                        editButton
                            .padding(.trailing, 8)
                    }

                    Text("\(playerRows.count)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            
            // Player rows
            VStack(spacing: 0) {
                ForEach($playerRows) { $row in
                    let index = indexOfRow(row.id)
                    let canDelete = playerRows.count > 2
                    
                    SwipeToDeleteWrapper(
                        canDelete: canDelete,
                        isEditMode: isEditMode,
                        onDelete: { removePlayer(rowId: row.id) }
                    ) {
                        PlayerInputRow(
                            index: index,
                            row: $row,
                            isLast: index == playerRows.count - 1,
                            canDelete: canDelete,
                            isEditMode: isEditMode,
                            draggedRowId: draggedRowId,
                            focusCoordinator: focusCoordinator,
                            onClearName: {
                                row.name = ""
                                onPersist()
                            },
                            onDelete: { removePlayer(rowId: row.id) },
                            onDragStart: { self.draggedRowId = row.id }
                        )
                    }
                    .transition(.opacity)
                    .onDrop(of: [UTType(playerRowReorderTypeIdentifier) ?? .data], delegate: PlayerRowDropDelegate(
                        item: row,
                        items: $playerRows,
                        draggedItem: $draggedRowId,
                        onReorder: onPersist
                    ))
                    
                    if index < playerRows.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }

                Divider()
                    .padding(.leading, 52)

                HStack(spacing: 8) {
                    Button(action: addPlayer) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(accentColor)
                            }
                            
                            Text("Add Player")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(accentColor)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAddPlayer)
                    .opacity(canAddPlayer ? 1 : 0)
                    .accessibilityHidden(!canAddPlayer)

                    Spacer(minLength: 8)

                    if !showsPlayerSummary {
                        resetButton
                            .frame(width: 44, height: 44)
                            .opacity(isEditMode && canResetPlayers ? 1 : 0)
                            .scaleEffect(isEditMode && canResetPlayers ? 1 : 0.94)
                            .allowsHitTesting(isEditMode && canResetPlayers)
                            .accessibilityHidden(!isEditMode || !canResetPlayers)

                        editButton
                            .frame(minWidth: 44, minHeight: 44)
                            .opacity(canEditPlayers ? 1 : 0)
                            .scaleEffect(canEditPlayers ? 1 : 0.94)
                            .allowsHitTesting(canEditPlayers)
                            .accessibilityHidden(!canEditPlayers)
                            .animation(.easeOut(duration: 0.16), value: canEditPlayers)
                    }
                }
                .frame(minHeight: 56)
                .padding(.horizontal, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(raisedSurfaceColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(18)
        .cardSurface(cornerRadius: 22)
        .onChange(of: playerRows.map { $0.id }) { _, newIds in
            focusCoordinator.setOrder(newIds)
        }
        .onChange(of: canEditPlayers) { _, canEdit in
            if !canEdit {
                isEditMode = false
            }
        }
        .onAppear {
            focusCoordinator.setOrder(playerRows.map { $0.id })
        }
    }
    
    // MARK: - Private Helpers
    
    private func indexOfRow(_ id: UUID) -> Int {
        playerRows.firstIndex(where: { $0.id == id }) ?? 0
    }

    private var editButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditMode.toggle()
            }
        }) {
            Text(isEditMode ? "Done" : "Edit")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(accentColor.opacity(0.10)))
                .overlay(Capsule().stroke(accentColor.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var resetButton: some View {
        Button(action: {
            onReset?()
            isEditMode = false
        }) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(accentColor.opacity(0.10)))
                .overlay(Circle().stroke(accentColor.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset players")
    }
    
    private func addPlayer() {
        guard playerRows.count < 8 else { return }
        HapticFeedback.light()
        let newRow = PlayerNameRow()
        withAnimation(.smooth(duration: 0.24)) {
            playerRows.append(newRow)
        }
        focusCoordinator.setOrder(playerRows.map { $0.id })
        focusCoordinator.clearFocus()
        onPersist()
    }
    
    private func removePlayer(rowId: UUID) {
        guard playerRows.count > 2 else { return }
        HapticFeedback.light()
        
        guard let indexToRemove = playerRows.firstIndex(where: { $0.id == rowId }) else { return }
        
        let newFocusId: UUID?
        if focusCoordinator.focusedId == rowId {
            if indexToRemove > 0 {
                newFocusId = playerRows[indexToRemove - 1].id
            } else if playerRows.count > 1 {
                newFocusId = playerRows[1].id
            } else {
                newFocusId = nil
            }
        } else {
            newFocusId = focusCoordinator.focusedId
        }
        
        withAnimation(.smooth(duration: 0.24)) {
            playerRows.remove(at: indexToRemove)
            if playerRows.count == 2 {
                isEditMode = false
            }
        }
        focusCoordinator.setOrder(playerRows.map { $0.id })
        onPersist()
        
        if let newFocusId = newFocusId {
            DispatchQueue.main.async {
                focusCoordinator.focus(newFocusId)
            }
        }
    }
}

// MARK: - Player Row Drop Delegate

struct PlayerRowDropDelegate: DropDelegate {
    let item: PlayerNameRow
    @Binding var items: [PlayerNameRow]
    @Binding var draggedItem: UUID?
    let onReorder: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
        
        HapticFeedback.light()
        onReorder()
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Swipe To Delete Wrapper

struct SwipeToDeleteWrapper<Content: View>: View {
    let canDelete: Bool
    let isEditMode: Bool
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteButtonWidth: CGFloat = 80
    private let deleteThreshold: CGFloat = 50
    private let dragHandleZoneWidth: CGFloat = 56
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Red delete area - positioned on the right, revealed as content slides left
                HStack(spacing: 0) {
                    Spacer()
                    
                    deleteButton
                        .frame(width: deleteButtonWidth)
                        .opacity(deleteRevealOpacity)
                        .allowsHitTesting(canDelete && offset < 0)
                        .accessibilityHidden(!canDelete || offset >= 0)
                }
                
                // Main content with swipe gesture
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme))
                    .offset(x: offset)
                    .simultaneousGesture(swipeGesture)
            }
        }
        .frame(height: 56)
        .clipped()
        .onChange(of: isEditMode) { _, newValue in
            // Close swipe menu when entering edit mode
            if newValue && offset != 0 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    offset = 0
                }
            }
        }
    }
    
    private var deleteButton: some View {
        Button {
            HapticFeedback.medium()
            withAnimation(.easeInOut(duration: 0.2)) {
                offset = 0
            }
            onDelete()
        } label: {
            ZStack {
                Color.red
                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var deleteRevealOpacity: Double {
        guard canDelete else { return 0 }
        return min(1, Double(max(0, -offset) / 16))
    }
    
    @State private var startOffset: CGFloat = 0
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                guard canDelete else { return }
                
                // Check if gesture started in valid zone (not over drag handle)
                if !isSwiping {
                    let startX = value.startLocation.x
                    // Only start swipe if not in the drag handle zone on the left,
                    // OR if the menu is already open
                    guard startX > dragHandleZoneWidth || offset < 0 else { return }
                    
                    // IMPORTANT: Only engage swipe if horizontal movement dominates
                    // This prevents conflict with vertical scrolling
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)
                    
                    // Require horizontal to be at least 1.5x vertical to be considered a swipe
                    guard horizontalDistance > verticalDistance * 1.5 else { return }
                    
                    isSwiping = true
                    startOffset = offset // Remember where we started
                }
                
                guard isSwiping else { return }
                
                // Calculate new offset: start position + drag translation
                let translation = value.translation.width
                let targetOffset = startOffset + translation
                
                // Clamp the offset
                if targetOffset > 0 {
                    // Don't allow swiping past closed (with slight rubber band)
                    offset = targetOffset * 0.2
                } else if targetOffset < -deleteButtonWidth {
                    // Rubber band effect when swiping past fully open
                    let overshoot = -targetOffset - deleteButtonWidth
                    offset = -deleteButtonWidth - (overshoot * 0.3)
                } else {
                    // Normal range: directly follow finger
                    offset = targetOffset
                }
            }
            .onEnded { value in
                guard canDelete && isSwiping else {
                    isSwiping = false
                    return
                }
                
                isSwiping = false
                
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                // Determine if we should snap open or closed based on position and velocity
                let shouldOpen = (-offset > deleteThreshold) || (velocity < -200 && offset < 0)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if shouldOpen {
                        offset = -deleteButtonWidth
                        HapticFeedback.light()
                    } else {
                        offset = 0
                    }
                }
            }
    }
}

// MARK: - Player Input Row

struct PlayerInputRow: View {
    let index: Int
    @Binding var row: PlayerNameRow
    let isLast: Bool
    let canDelete: Bool
    let isEditMode: Bool
    let draggedRowId: UUID?
    @ObservedObject var focusCoordinator: FocusCoordinator
    let onClearName: () -> Void
    let onDelete: () -> Void
    let onDragStart: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDragging: Bool {
        draggedRowId == row.id
    }
    
    private var isFocused: Bool {
        focusCoordinator.focusedId == row.id
    }
    
    private var hasName: Bool {
        !row.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var dragPreviewFill: Color {
        DesignColor.color(.surfacePrimary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var dragPreviewBorder: Color {
        visualTheme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.systemGray4)
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
    }
    
    /// Display name for drag preview
    private var displayName: String {
        let trimmed = row.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Player \(index + 1)" : trimmed
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag handle with custom preview and custom UTType (prevents text field drops)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(isFocused ? 0.18 : 0.10))
                    .frame(width: 34, height: 34)

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDragging ? accentColor : accentColor.opacity(0.72))
            }
            .contentShape(Rectangle())
            .onDrag {
                onDragStart()
                // Use custom UTType so text fields won't accept this drop
                let provider = NSItemProvider()
                provider.registerDataRepresentation(forTypeIdentifier: playerRowReorderTypeIdentifier, visibility: .ownProcess) { completion in
                    let data = row.id.uuidString.data(using: .utf8) ?? Data()
                    completion(data, nil)
                    return nil
                }
                return provider
            } preview: {
                // Custom drag preview - shows the player name in a styled capsule
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                    Text(displayName)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(dragPreviewFill)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(dragPreviewBorder, lineWidth: 0.75)
                )
            }
            
            // Text field
            FocusableTextFieldRepresentable(
                id: row.id,
                placeholder: "Player \(index + 1)",
                text: $row.name,
                isLast: isLast,
                coordinator: focusCoordinator
            )
            .frame(height: 44)
            
            // Clear name button (X) - only when name is non-empty
            // Uses onTapGesture with high priority to ensure it responds before swipe gesture
            if hasName {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.systemGray3))
                    .frame(width: 44, height: 44) // Larger hit target
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded {
                                HapticFeedback.light()
                                onClearName()
                            }
                    )
            }
            
            // Edit mode trash button (visible delete affordance)
            if isEditMode && canDelete {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44) // Larger hit target
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded {
                                HapticFeedback.medium()
                                onDelete()
                            }
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isDragging
                        ? AppBrandPalette.brandBlue.opacity(colorScheme == .dark ? 0.26 : 0.12)
                        : (isFocused ? accentColor.opacity(0.08) : Color.clear)
                )
        )
        .contentShape(Rectangle())
    }
}
