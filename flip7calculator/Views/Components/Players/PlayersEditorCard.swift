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
    
    @State private var draggedRowId: UUID?
    @State private var isEditMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Players")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                // Edit/Done button
                if playerRows.count > 2 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditMode.toggle()
                        }
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    .padding(.trailing, 8)
                }
                
                Text("\(playerRows.count)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
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
                .animation(.easeInOut(duration: 0.25), value: playerRows.count)
                .animation(.easeInOut(duration: 0.2), value: playerRows.map { $0.id })
                
                // Add player row
                if playerRows.count < 8 {
                    Divider()
                        .padding(.leading, 52)
                    
                    Button(action: addPlayer) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
                            
                            Text("Add Player")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(.blue)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: playerRows.map { $0.id }) { _, newIds in
            focusCoordinator.setOrder(newIds)
        }
        .onAppear {
            focusCoordinator.setOrder(playerRows.map { $0.id })
        }
    }
    
    // MARK: - Private Helpers
    
    private func indexOfRow(_ id: UUID) -> Int {
        playerRows.firstIndex(where: { $0.id == id }) ?? 0
    }
    
    private func addPlayer() {
        guard playerRows.count < 8 else { return }
        HapticFeedback.light()
        let newRow = PlayerNameRow()
        playerRows.append(newRow)
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
        
        playerRows.remove(at: indexToRemove)
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
                    
                    if canDelete {
                        deleteButton
                            .frame(width: deleteButtonWidth)
                    }
                }
                
                // Main content with swipe gesture
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color(.systemBackground))
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
    let focusCoordinator: FocusCoordinator
    let onClearName: () -> Void
    let onDelete: () -> Void
    let onDragStart: () -> Void
    
    private var isDragging: Bool {
        draggedRowId == row.id
    }
    
    private var hasName: Bool {
        !row.name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Display name for drag preview
    private var displayName: String {
        let trimmed = row.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Player \(index + 1)" : trimmed
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag handle with custom preview and custom UTType (prevents text field drops)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isDragging ? Color(.systemGray) : Color(.systemGray3))
                .frame(width: 32, height: 32)
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
                            .foregroundStyle(.secondary)
                        Text(displayName)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
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
        .background(isDragging ? Color(.systemGray5).opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
    }
}

