//
//  LikeButtonPosition.swift
//  Pods
//
//  Created by Rodrigo Leite on 25/11/16.
//
//

import Foundation

/**
 Defines the position of the like button.
 
 - topLeading:  like button is constrained to the top and leading anchors of its superview.
 - topTrailing: like button is constrained to the top and trailing anchors of its superview.
 */
public enum ActionButtonPosition {

    case bottomLeading
    
    func xAnchorAttribute() -> NSLayoutAttribute {
        switch self {
        case .bottomLeading:
            return .leading
        }
    }
    
    func yAnchorAttribute() -> NSLayoutAttribute {
        switch self {
        case .bottomLeading:
            return .bottom
        }
    }
}
