import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = AppListViewModel()
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            TitleBar(vm: vm)

            Divider().opacity(0.2)

            if vm.apps.isEmpty {
                EmptyStateView(isTargeted: $isTargeted, onDrop: handleDrop)
            } else {
                AppListView(vm: vm, isTargeted: $isTargeted, onDrop: handleDrop)
            }

            Divider().opacity(0.2)

            LoginItemRow(vm: vm)

            Divider().opacity(0.2)

            BottomBar(vm: vm)
        }
        .background(.regularMaterial)
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    if url.pathExtension == "app" { vm.addApp(url: url) }
                }
            }
        }
        return true
    }
}

// MARK: - Title Bar

struct TitleBar: View {
    @ObservedObject var vm: AppListViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Staggered")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            if !vm.apps.isEmpty {
                LaunchModeToggle(isParallel: $vm.isParallel)
                    .onChange(of: vm.isParallel) { _ in vm.save() }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Launch Mode Toggle

struct LaunchModeToggle: View {
    @Binding var isParallel: Bool

    var body: some View {
        HStack(spacing: 0) {
            ModeButton(label: "Sequence", icon: "arrow.right", selected: !isParallel) {
                isParallel = false
            }
            ModeButton(label: "Parallel", icon: "arrow.triangle.branch", selected: isParallel) {
                isParallel = true
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ModeButton: View {
    let label: String
    let icon: String
    let selected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? .primary : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                selected
                    ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                    : AnyShapeStyle(isHovered ? Color.primary.opacity(0.05) : Color.clear),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: selected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @Binding var isTargeted: Bool
    var onDrop: ([NSItemProvider]) -> Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isTargeted ? Color.accentColor.opacity(0.06) : Color.clear)
                )
                .padding(24)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                    Image(systemName: "plus.app")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(.secondary)
                }
                Text("Drop apps here")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                Text("Or click Add App below to browse")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: onDrop)
    }
}

// MARK: - App List

struct AppListView: View {
    @ObservedObject var vm: AppListViewModel
    @Binding var isTargeted: Bool
    var onDrop: ([NSItemProvider]) -> Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: vm.isParallel ? "arrow.triangle.branch" : "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(vm.isParallel
                    ? "Each delay starts from boot simultaneously"
                    : "Delays are cumulative — each app waits after the previous")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)

            Divider().opacity(0.15)

            List {
                ForEach($vm.apps) { $app in
                    AppRow(
                        app: $app,
                        isParallel: vm.isParallel,
                        onChange: { vm.save() },
                        onDelete: { vm.removeApp(id: app.id) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.visible)
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                }
                .onMove(perform: vm.moveApp)
                .onDelete(perform: vm.removeApp)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.clear)
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: onDrop)
        .overlay(
            Group {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .background(Color.accentColor.opacity(0.04)
                            .clipShape(RoundedRectangle(cornerRadius: 4)))
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        )
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }
}

// MARK: - App Row

struct AppRow: View {
    @Binding var app: DelayedApp
    let isParallel: Bool
    var onChange: () -> Void
    var onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle — visible on hover
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHovered ? Color.secondary.opacity(0.4) : Color.clear)
                .frame(width: 16)

            // App icon
            Group {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 36, height: 36)

            // Name + path
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(app.bundlePath)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(isParallel ? "after" : "delay")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            DelayControl(seconds: $app.delaySeconds, onChange: onChange)

            // Per-row delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(isHovered ? Color.secondary.opacity(0.6) : Color.clear)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .help("Remove \(app.name)")
        }
        .padding(.vertical, 5)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - Delay Control

struct DelayControl: View {
    @Binding var seconds: Int
    var onChange: () -> Void

    @State private var editText: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            StepButton(icon: "minus") {
                seconds = max(0, seconds - 1)
                editText = "\(seconds)"
                onChange()
            }

            ZStack {
                if isEditing {
                    TextField("", text: $editText)
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .focused($fieldFocused)
                        .onSubmit { commitEdit() }
                        .onExitCommand { cancelEdit() }
                } else {
                    Text("\(seconds)s")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 44)
            .contentShape(Rectangle())
            .onTapGesture { if !isEditing { beginEdit() } }

            StepButton(icon: "plus") {
                seconds = min(3600, seconds + 1)
                editText = "\(seconds)"
                onChange()
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    fieldFocused ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.08),
                    lineWidth: 1
                )
        )
        .onAppear { editText = "\(seconds)" }
        .onChange(of: seconds) { newVal in
            if !isEditing { editText = "\(newVal)" }
        }
    }

    private func beginEdit() {
        editText = "\(seconds)"
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { fieldFocused = true }
    }

    private func commitEdit() {
        if let val = Int(editText) { seconds = max(0, min(3600, val)) }
        editText = "\(seconds)"
        isEditing = false
        fieldFocused = false
        onChange()
    }

    private func cancelEdit() {
        editText = "\(seconds)"
        isEditing = false
        fieldFocused = false
    }
}

struct StepButton: View {
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    isHovered ? Color.primary.opacity(0.06) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Login Item Row

struct LoginItemRow: View {
    @ObservedObject var vm: AppListViewModel

    var statusColor: Color {
        vm.loginItemEnabled ? .green : .secondary
    }

    var statusText: String {
        vm.loginItemEnabled
            ? "Registered — will run delayed launches on login"
            : "Not registered — apps will not be delayed at login"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: vm.loginItemEnabled ? "checkmark.circle.fill" : "moon.zzz")
                    .font(.system(size: 15))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Run at Login")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { vm.loginItemEnabled },
                set: { _ in vm.toggleLoginItem() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
            .disabled(vm.apps.isEmpty)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            if vm.apps.isEmpty {
                Text("Add apps above before enabling")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Bottom Bar

struct BottomBar: View {
    @ObservedObject var vm: AppListViewModel
    @State private var showingFilePicker = false

    var body: some View {
        HStack(spacing: 10) {
            Button { showingFilePicker = true } label: {
                Label("Add App", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "app")!],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    for url in urls { vm.addApp(url: url) }
                }
            }

            if !vm.apps.isEmpty {
                Button {
                    vm.apps.removeAll()
                    vm.save()
                } label: {
                    Label("Clear All", systemImage: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Spacer()

            if !vm.apps.isEmpty {
                Text("\(vm.apps.count) app\(vm.apps.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
