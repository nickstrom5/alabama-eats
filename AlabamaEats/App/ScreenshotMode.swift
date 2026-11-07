import Foundation
import CoreLocation
import UIKit

/// `-screenshot <name>` opens one screen with fixed state for App Store screenshots (scripts/capture-screenshots.sh).
/// Names: home, bbq, meat3, oysters, catfish, greek, honors, oldest, inspections, detail, map, saved, about.
enum ScreenshotMode {
    /// Debug builds only: an App Store build ignores the launch argument, so no one can reach seeded screens or fake locations.
    static var name: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }
    static var isActive: Bool { name != nil }

    @MainActor
    static func apply(to model: AppModel) {
        guard let name, model.isLoaded else { return }
        model.filters = Filters()
        // downtown Birmingham, among the most picks, so "nearest" lists have distances without a permission prompt
        model.screenshotLocation = CLLocation(latitude: 33.5186, longitude: -86.8104)
        // by name and town, ignoring case, so a rebuild with a slightly different casing still finds the place; the hand-checked one first
        let pick = { (n: String, town: String?) -> Place? in
            let hits = model.places.filter { $0.name.caseInsensitiveCompare(n) == .orderedSame && (town == nil || $0.city == town) }
            return hits.first(where: \.handChecked) ?? hits.first
        }
        for p in [pick("Gus's Hot Dogs", "Birmingham"), pick("The Bright Star", "Bessemer"), pick("Wintzell's Oyster House", "Mobile")]
            .compactMap({ $0 }) where !model.isSaved(p) {
            model.toggleSaved(p)
        }
        let open = { (g: Guide) in model.tab = .guides; model.selectedGuide = g; model.guidesPath = [.guide(g)] }
        switch name {
        case "bbq": open(.bbq)
        case "meat3": open(.meat3)
        case "oysters":
            // Orange Beach, among the Gulf oyster bars
            model.screenshotLocation = CLLocation(latitude: 30.2697, longitude: -87.5866)
            open(.oysters)
        case "catfish": open(.catfish)
        case "greek": open(.greek)
        case "honors": open(.honors)
        case "oldest": open(.oldest)
        case "inspections": open(.inspections)
        case "detail":
            // The Bright Star: a James Beard America's Classic with its 1915 year at this address and its note, seen from across
            // downtown Bessemer (about a mile off, so the distance reads as one)
            model.screenshotLocation = CLLocation(latitude: 33.3950, longitude: -86.9690)
            open(.greek)
            if let p = pick("The Bright Star", "Bessemer") ?? model.places.first {
                model.selectedPlace = p; model.guidesPath.append(.place(p))
            }
        case "map":
            // downtown Birmingham's Morris Avenue and 2nd Avenue North: picks and honors close together, so the shot shows pins
            model.screenshotLocation = CLLocation(latitude: 33.5150, longitude: -86.8050)
            model.tab = .map
        case "saved": model.tab = .saved
        case "about": model.tab = .about
        default: model.tab = .guides; model.selectedGuide = nil
        }
        // iPad shows the place column next to every list, so give each shot a place instead of "Pick a place": a different
        // honored or hand-checked one per shot.
        guard UIDevice.current.userInterfaceIdiom == .pad, model.selectedPlace == nil else { return }
        let place: Place? = switch name {
        case "home": pick("The Bright Star", "Bessemer")
        case "bbq": pick("Big Bob Gibson Bar-B-Q", "Decatur")
        case "meat3": pick("Niki's West", "Birmingham")
        case "oysters": pick("Wintzell's Oyster House", "Mobile")
        case "catfish": pick("Ezell's Fish Camp", "Lavaca")
        case "greek": pick("Gus's Hot Dogs", "Birmingham")
        case "honors": pick("Bottega", "Birmingham")
        case "oldest": pick("The Peerless Saloon & Grille", "Anniston")
        case "inspections": pick("Chris' Famous Hotdogs", "Montgomery")
        case "map": pick("Pizza Grace", "Birmingham")
        case "saved": pick("Gus's Hot Dogs", "Birmingham")
        case "about": nil
        default: pick("The Bright Star", "Bessemer")
        }
        model.selectedPlace = place
    }
}
