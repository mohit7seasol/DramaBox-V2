//
//  AnalyticsWrapper.swift
//  Hidden Camera Finder
//
//  Created by Ashish on 24/02/23.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

enum AnalyticEvent: String {
    
    case Home
    case HomeTab
    case MovieList
    case TVScreen
    case MovieDetail
    case TVDetails
    case TVList
    case MediaPreview
    case IPTVList
    case IPTVChannel
    case Language
    case Setting
    case Subscription
    case CelebrityDetails
    case Provider
    case Favourite
    case searchMovie
    case CelebrityMovies
    case CelebrityTVshows
    case CelebritySearch
    case aboutUs
}

func logAnalyticView(title: String, Screen: String) {
    Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: title, AnalyticsParameterScreenClass: Screen])
}

func logAnalyticAction(title: String, status: AnalyticEvent) {
    Analytics.logEvent(status.rawValue, parameters: ["name": title, "status": status])
}

func logAnalyticActionWithParams(_ name: AnalyticEvent, parameters: [String : Any]?)
{
    Analytics.logEvent(name.rawValue, parameters: parameters)
}
