import Foundation

/// The app's web pages and support address, in one place.
/// The site is GitHub Pages at the project address until alabama.eatsranked.com resolves (Nick adds a Cloudflare CNAME
/// alabama -> nickstrom5.github.io, DNS only; then scripts/make-site.py sets CUSTOM_DOMAIN). GitHub forwards these github.io
/// links to the custom domain after the switch, so a shipped build keeps working; point them at the new domain in the next update.
enum Links {
    static let site = URL(string: "https://nickstrom5.github.io/alabama-eats/")!
    /// The app's data updates: scripts/publish_app_data.py writes docs/data/app/ (OTA-DATA.md).
    static let appData = URL(string: site.absoluteString + "data/app/")!
    static let privacy = URL(string: site.absoluteString + "privacy.html")!
    static let terms = URL(string: site.absoluteString + "terms.html")!
    /// the Alabama Alcoholic Beverage Control Board: it publishes no licensee list, so "Serves alcohol" is unknown here
    static let licenses = URL(string: "https://alabcboard.gov/")!
    /// ADPH's Food Establishment Scores page, with its statewide search (every county's scores; search-only, so only linked)
    static let inspections = URL(string: "https://www.alabamapublichealth.gov/foodscores/index.html")!
    /// the two lists whose scores the app shows, each as the county publishes it
    static let montgomeryScores = URL(string: "https://www.alabamapublichealth.gov/montgomery/food-scores.html")!
    static let jeffersonScores = URL(string: "https://www.jcdh.org/SitePages/Programs-Services/Scores-Lists/Food/FoodServScores.aspx")!
    /// the Mobile County Health Department's own restaurant ratings (its site; not read by this app)
    static let mobileRatings = URL(string: "https://mchd.org/restaurant-ratings-mobile/")!

    /// A score list's code in the data -> its publisher and page.
    static func scoreList(_ code: String) -> (name: String, url: URL)? {
        switch code {
        case "montgomery": ("Montgomery County Health Department", montgomeryScores)
        case "jefferson": ("Jefferson County Department of Health", jeffersonScores)
        default: nil
        }
    }
    static let supportEmail = "nick@eatsranked.com"

    static var correctionEmail: URL {
        URL(string: "mailto:\(supportEmail)?subject=Alabama%20Eats%20correction")!
    }

    // MARK: Share

    /// The web app. It opens a place's panel from the hash, explore/#p=<id> (readHash in scripts/explore.js), using the app's ids.
    static let explore = URL(string: site.absoluteString + "explore/")!

    /// What Share sends: the place's own page in the web app, never an Apple Maps or Google link (Apple Maps has its own button).
    /// The id is escaped the way the page's encodeURIComponent would escape it. The web app lists every place
    /// the app does (a unit test checks the ids against docs/data).
    /// The web app lists restaurants only: the venues the app hides by default (stadium stands, gas-station counters) aren't there.
    static func onWeb(_ place: Place) -> Bool { !place.isVenue }
    static func share(_ place: Place) -> URL {
        guard onWeb(place), let id = place.id.addingPercentEncoding(withAllowedCharacters: uriComponent),
              let url = URL(string: explore.absoluteString + "#p=" + id) else { return explore }
        return url
    }

    /// The text that goes with the link: the place, its town and the app. No street address, which Messages turns into a Maps link.
    static func shareMessage(_ place: Place) -> String {
        [place.name, place.city ?? ""].filter { !$0.isEmpty }.joined(separator: ", ") + ", on Alabama Eats"
    }

    /// What encodeURIComponent leaves as is.
    private static let uriComponent = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
}
