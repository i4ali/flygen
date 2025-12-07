import Foundation

struct TextContent: Codable, Equatable {
    var headline: String = ""
    var subheadline: String?
    var bodyText: String?
    var date: String?
    var time: String?
    var venueName: String?
    var address: String?
    var price: String?
    var discountText: String?
    var ctaText: String?
    var phone: String?
    var email: String?
    var website: String?
    var socialHandle: String?
    var additionalInfo: [String]?
    var finePrint: String?

    /// Returns true if the headline (required field) is not empty
    var isValid: Bool {
        !headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns all non-nil, non-empty text fields as a dictionary
    var allTextFields: [String: String] {
        var fields: [String: String] = [:]

        if !headline.isEmpty { fields["headline"] = headline }
        if let v = subheadline, !v.isEmpty { fields["subheadline"] = v }
        if let v = bodyText, !v.isEmpty { fields["bodyText"] = v }
        if let v = date, !v.isEmpty { fields["date"] = v }
        if let v = time, !v.isEmpty { fields["time"] = v }
        if let v = venueName, !v.isEmpty { fields["venueName"] = v }
        if let v = address, !v.isEmpty { fields["address"] = v }
        if let v = price, !v.isEmpty { fields["price"] = v }
        if let v = discountText, !v.isEmpty { fields["discountText"] = v }
        if let v = ctaText, !v.isEmpty { fields["ctaText"] = v }
        if let v = phone, !v.isEmpty { fields["phone"] = v }
        if let v = email, !v.isEmpty { fields["email"] = v }
        if let v = website, !v.isEmpty { fields["website"] = v }
        if let v = socialHandle, !v.isEmpty { fields["socialHandle"] = v }
        if let v = finePrint, !v.isEmpty { fields["finePrint"] = v }

        return fields
    }
}
