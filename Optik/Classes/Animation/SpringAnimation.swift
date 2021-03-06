//
//  SpringAnimation.swift
//  Optik
//
//  Created by Htin Linn on 7/18/16.
//  Copyright © 2016 Prolific Interactive. All rights reserved.
//

import UIKit

/// Animation that moves a given view to a new target using spring physics.
internal final class SpringAnimation<T: VectorRepresentable, U: AnimatableProperty where T == U.PropertyType> {
    
    // MARK: - Properties
    
    /// View to be animated.
    private(set) weak var view: UIView?
    
    /// Friction constant used when calculating animation frames.
    var friction: CGFloat {
        get {
            return springIntegrator.friction
        }
        set {
            springIntegrator.friction = newValue
        }
    }
    
    /// Spring constant used when calculating animation frames.
    var spring: CGFloat {
        get {
            return springIntegrator.spring
        }
        set {
            springIntegrator.spring = newValue
        }
    }
    
    /// Callback for each animation frame.
    var onTick: ((finished: Bool) -> ())?
    
    // MARK: - Private properties
    
    private var currentVector: T.InterpolatableType
    private var currentVelocity: T.InterpolatableType
    private let toVector: T.InterpolatableType
    private let threshold: CGFloat
    
    private var springIntegrator: SpringIntegrator<T.InterpolatableType>
    
    private let lens: Lens<UIView, T.InterpolatableType>
    
    // MARK: - Init/Deinit

    /**
     Initializes a spring animation with given parameters.
     
     - parameter view:     View to animate.
     - parameter target:   Destination for the view.
     - parameter velocity: Starting velocity of the view.
     - parameter property: Property to animate.
     
     - returns: An initialized spring animation object.
     */
    init(view: UIView, target: T, velocity: T, property: U) {
        self.view = view
        
        threshold = property.threshold
        lens = property.lens
        
        toVector = target.vector
        currentVelocity = velocity.vector
        currentVector = lens.get(view)
        
        springIntegrator = SpringIntegrator()
    }
    
    // MARK: - Private functions
    
    private func isAnimationComplete() -> Bool {
        let currentValues = currentVector.values
        let toValues = toVector.values
        
        for (index, value) in currentValues.enumerate() {
            if abs(value - toValues[index]) > threshold {
                return false
            }
        }
        
        return true
    }
    
}

// MARK: - Protocol conformance

// MARK: Animation

extension SpringAnimation: Animation {
    
    func animationTick(timeElapsed: CFTimeInterval, inout finished: Bool) {
        guard let view = view else {
            finished = true
            return
        }
        
        let result = springIntegrator.integrate(
            currentVector - toVector,
            velocity: currentVelocity,
            dt: timeElapsed
        )
        
        currentVector = currentVector + result.dpdt * CGFloat(timeElapsed)
        currentVelocity = currentVelocity + result.dvdt * CGFloat(timeElapsed)
        
        lens.set(currentVector, view)

        if isAnimationComplete() {
            lens.set(toVector, view)
            finished = true
            
            onTick?(finished: true)
        } else {
            onTick?(finished: false)
        }
    }
    
}
