import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: RepoStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RepoView()
                .tabItem {
                    Label("Repo", systemImage: "shippingbox.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .sheet(
            isPresented: $patchDraftCoordinator.isPresentingImport
        ) {
            PatchImportView()
        }
        .sheet(
            isPresented: $fileOperationCoordinator.isPresenting
        ) {
            FileOperationView()
        }
    }
}