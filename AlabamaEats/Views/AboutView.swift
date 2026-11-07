import SwiftUI

struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ALABAMA EATS").displayFont(32).foregroundStyle(Theme.green)
                    Text("A free guide to \(model.restaurantCount.formatted()) Alabama restaurants, with MICHELIN and James Beard honors and hand-checked lists of Alabama's own: white-sauce and pit barbecue, meat-and-threes, Gulf oyster bars, catfish houses, Greek diners and hot dog stands, and the oldest places. No account, no ads, no tracking.")
                        .font(.subheadline).foregroundStyle(Theme.ink2)
                    Text("Alabama Eats is an independent app by Nicholas Soderstrom. It is not affiliated with, endorsed by or operated by the State of Alabama, the Alabama Department of Public Health or any county health department (including the Jefferson County Department of Health and the Mobile County Health Department), the Alabama Alcoholic Beverage Control Board, the Alabama Tourism Department, any visitors bureau, any university, the MICHELIN Guide, the James Beard Foundation, Apple, or any restaurant or chain. Other names are trademarks of their owners.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 4)
            }
            Section("How the lists are built") {
                Text("Hand-checked lists (white sauce and barbecue, meat-and-threes, Gulf oysters and seafood, catfish houses, Greek diners and hot dogs, and the oldest places) include only places checked against a 2025 or 2026 source: the Alabama Tourism Department's Catfish Trail (June 2026), the Gulf Shores & Orange Beach and Mobile tourism boards, the MICHELIN Guide, or a dated local story. Founding years mean the year it opened at this address.")
                Text("Honors are facts: the MICHELIN Guide American South's Bib Gourmands and Recommended restaurants (no Alabama restaurant has a star), and James Beard Foundation honors, from an America's Classic to the 2025 and 2026 semifinalists.")
                Text("Alabama publishes no statewide open list of its restaurants. This app starts from open map listings (Overture Maps) and keeps the kinds that proved reliable where official lists exist: in Jefferson County, 78% of the high-confidence listings matched a business the county inspects, against 13 to 21% for the kinds left out. Whether a place serves alcohol is unknown here, never no. Adult clubs are left out, and stadium, airport and campus stands are hidden with the non-restaurants. Website links are checked, and any that no longer belong to the place are left out.")
                Text("Inspection scores: the Alabama Department of Public Health and its county health departments score restaurants on a 100-point scale (85 to 100 is satisfactory; below 85 brings a follow-up inspection, and below 60 closes the place). Montgomery County and Jefferson County publish each establishment's latest score as a list; this app shows that score exactly as published, with its date and the county's name. It is the county's number, not a grade, and the app computes none. Other counties' scores are reached only through ADPH's search, so places there link to it.")
                Text("Ratings, reviews, hours and photos are Apple Maps' own, shown live in Apple's place card. This app doesn't store or rank by them.")
            }
            .font(.subheadline).foregroundStyle(Theme.ink2)
            Section("Sources") {
                source("Montgomery County Health Department", "Montgomery County Food Inspection Scores (alabamapublichealth.gov): each establishment's latest score and date\(model.permitsUpdated.isEmpty ? "" : ", as of the page's \(DayFormat.text(model.permitsUpdated) ?? model.permitsUpdated) update").", Links.montgomeryScores.absoluteString)
                source("Jefferson County Department of Health", "Food Service Scores: the most recent scored inspection of each permitted establishment (jcdh.org). JCDH also makes non-scored visits, so a place missing from the list isn't a zero.", Links.jeffersonScores.absoluteString)
                source("Alabama Department of Public Health", "Food Establishment Scores and the statewide search. Linked from each place outside the two counties.", Links.inspections.absoluteString)
                source("Overture Maps Foundation", "Restaurant listings and websites come from Overture Maps Foundation places data (overturemaps.org)\(model.overtureRelease.map { ", release \($0)" } ?? ""), filtered and reformatted for this app.\n• Data from Meta, Microsoft, DAC and BrightQuery. Available under CDLA Permissive 2.0.\n• Data from Foursquare. \(foursquareCopyright) Available under Apache 2.0. Foursquare data was transformed to the Overture schema; this app further filtered and reformatted it. See the NOTICE below.\n• Data from AllThePlaces. Available under CC0 1.0.\nResearched places are put on the map with Overture Maps addresses data (open address sources under permissive licenses, docs.overturemaps.org/attribution).", "https://overturemaps.org")
                source("Honors", "MICHELIN Guide distinctions and James Beard Foundation awards are reported as facts and checked by hand against the Guide's site and the Foundation's announcements. MICHELIN and the MICHELIN Guide are trademarks of Michelin. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation. Other names belong to their owners.", "https://guide.michelin.com/us/en/alabama/restaurants")
                source("Maps", "Maps, place cards and directions by Apple Maps.", nil)
            }
            Section("Licenses") {
                NavigationLink("Community Data License Agreement – Permissive 2.0") { LicenseText(file: "CDLA-Permissive-2.0", title: "CDLA Permissive 2.0") }
                NavigationLink("Apache License 2.0") { LicenseText(file: "Apache-2.0", title: "Apache License 2.0") }
                NavigationLink("Foursquare OS Places NOTICE") { LicenseText(file: "Foursquare-NOTICE", title: "Foursquare NOTICE") }
            }
            Section("Privacy") {
                Text("The app collects nothing. Your location, if you allow it, only sorts lists by distance and shows where you are on the map, on this device. Saved places stay on this device.")
                    .font(.subheadline).foregroundStyle(Theme.ink2)
                DataUpdatesNote()
                    .font(.footnote).foregroundStyle(Theme.muted)
                Link("Privacy policy", destination: Links.privacy)
                Link("Terms of use", destination: Links.terms)
            }
            Section("Help") {
                Link("Report a missing or closed place", destination: Links.correctionEmail)
                Link("Email \(Links.supportEmail)", destination: URL(string: "mailto:\(Links.supportEmail)")!)
                Link("Website", destination: Links.site)
                Text("Data as of \(DayFormat.text(model.generated) ?? model.generated). Places open and close; check before you go. Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("About")
        .tint(Theme.green)
    }

    /// the copyright line exactly as the bundled Foursquare NOTICE has it, so the two can't disagree
    private var foursquareCopyright: String {
        guard let url = Bundle.main.url(forResource: "Foursquare-NOTICE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let line = text.split(separator: "\n").first(where: { $0.hasPrefix("©") }) else { return "© Foursquare Labs, Inc. All rights reserved." }
        return line.trimmingCharacters(in: .whitespaces)
    }

    @ViewBuilder
    private func source(_ name: String, _ detail: String, _ url: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let url, let u = URL(string: url) { Link(name, destination: u).font(.subheadline.weight(.semibold)) }
            else { Text(name).font(.subheadline.weight(.semibold)) }
            Text(detail).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

/// A bundled license text (Resources/Licenses), reflowed rather than shown as raw 80-column lines.
struct LicenseText: View {
    let file: String
    let title: String

    var body: some View {
        ScrollView {
            Text(text).font(.footnote).foregroundStyle(Theme.ink).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .inlineTitle(title)
    }

    private var text: String {
        guard let url = Bundle.main.url(forResource: file, withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return "License text missing." }
        // join hard-wrapped lines into paragraphs; keep blank lines and list items as breaks
        var out: [String] = []
        for para in raw.components(separatedBy: "\n\n") {
            let lines = para.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            var joined = ""
            for l in lines where !l.isEmpty {
                let startsItem = l.hasPrefix("–") || l.hasPrefix("-") || l.range(of: #"^\(?[a-z0-9]{1,3}[.)]\s"#, options: .regularExpression) != nil
                joined += joined.isEmpty ? l : (startsItem ? "\n" + l : " " + l)
            }
            if !joined.isEmpty { out.append(joined) }
        }
        return out.joined(separator: "\n\n")
    }
}
