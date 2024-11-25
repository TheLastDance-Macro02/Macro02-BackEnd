//
//  Welcome.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 17/11/24.
//

import Foundation
import Vapor

enum AllCarriers{
    struct GetAllCarriers: Codable {
        let data: [Carries]
    }

    struct Carries: Codable {
        let id: Int
        let code, name: String
        let logoImage: String?
        let isPost, isChinese: Bool
        let countryCode: String?
        let group: Int?
        let website: String?

        enum CodingKeys: String, CodingKey {
            case id, code, name
            case logoImage = "logo_image"
            case isPost = "is_post"
            case isChinese = "is_chinese"
            case countryCode = "country_code"
            case group, website
        }
    }
    
    //Response data decodable
    struct Welcome: Codable {
        let data: DataClass
    }

    struct DataClass: Codable {
        let id, trackingNumber: String
        let trackingNumbers: [TrackingNumber]
        let parcelIdentifier, originCountryCode: String
        let events: [Event]
        let dispatchCode: DispatchCode
        let couriers: [Courier]

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case trackingNumber = "tracking_number"
            case trackingNumbers = "tracking_numbers"
            case parcelIdentifier = "parcel_identifier"
            case originCountryCode = "origin_country_code"
            case events
            case dispatchCode = "dispatch_code"
            case couriers
        }
    }

    // MARK: - Courier
    struct Courier: Codable {
        let slug, crawlerCode, countryCode: String
        let logoImage: LogoImage

        enum CodingKeys: String, CodingKey {
            case slug
            case crawlerCode = "crawler_code"
            case countryCode = "country_code"
            case logoImage = "logo_image"
        }
    }

    // MARK: - LogoImage
    struct LogoImage: Codable {
        let path: String
    }


    // MARK: - DispatchCode
    struct DispatchCode: Codable {
        let id: Int
        let code, step, desc: String
    }

    // MARK: - Event
    struct Event: Codable {
        let datetime: String
        let timestamp: Date
        let dispatchCodeID: Int?
        let status: String
        let location: String?
        let courier: Courier

        enum CodingKeys: String, CodingKey {
            case datetime, timestamp
            case dispatchCodeID = "dispatch_code_id"
            case status, location, courier
        }
    }

    // MARK: - TrackingNumber
    struct TrackingNumber: Codable {
        let isMain: Bool
        let trackingNumber: String
        let crawlerCodes: [String]

        enum CodingKeys: String, CodingKey {
            case isMain = "is_main"
            case trackingNumber = "tracking_number"
            case crawlerCodes = "crawler_codes"
        }
    }
}


