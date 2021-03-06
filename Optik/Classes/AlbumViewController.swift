//
//  AlbumViewController.swift
//  Optik
//
//  Created by Htin Linn on 5/9/16.
//  Copyright © 2016 Prolific Interactive. All rights reserved.
//

import UIKit

/// View controller for displaying a collection of photos.
internal final class AlbumViewController: UIViewController {
    
    private struct Constants {
        static let SpacingBetweenImages: CGFloat = 40
        static let DismissButtonDimension: CGFloat = 60
        
        static let TransitionAnimationDuration: NSTimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    weak var imageViewerDelegate: ImageViewerDelegate? {
        didSet {
            guard let _ = imageViewerDelegate else {
                transitioningDelegate = nil
                
                transitionController.currentImageView = nil
                transitionController.transitionImageView = nil
                
                return
            }
            
            transitioningDelegate = transitionController
            
            transitionController.viewControllerToDismiss = self
            transitionController.currentImageView = { [weak self] in
                return self?.currentImageViewController?.imageView
            }
            transitionController.transitionImageView = { [weak self] in
                guard let currentImageIndex = self?.currentImageViewController?.index else {
                    return nil
                }
                
                return self?.imageViewerDelegate?.transitionImageView(forIndex: currentImageIndex)
            }
        }
    }
    
    // MARK: Private properties
    
    private var pageViewController: UIPageViewController
    private var currentImageViewController: ImageViewController? {
        guard let viewControllers = pageViewController.viewControllers where viewControllers.count == 1 else {
            return nil
        }
        
        return viewControllers[0] as? ImageViewController
    }
    
    private var imageData: ImageData
    private var initialImageDisplayIndex: Int
    private var activityIndicatorColor: UIColor?
    private var dismissButtonImage: UIImage?
    private var dismissButtonPosition: DismissButtonPosition
    
    private var cachedRemoteImages: [NSURL: UIImage] = [:]
    private var viewDidAppear: Bool = false
    
    private var transitionController: TransitionController = TransitionController()
    
    // MARK: - Init/Deinit
    
    init(imageData: ImageData,
         initialImageDisplayIndex: Int,
         activityIndicatorColor: UIColor?,
         dismissButtonImage: UIImage?,
         dismissButtonPosition: DismissButtonPosition) {
        
        self.imageData = imageData
        self.initialImageDisplayIndex = initialImageDisplayIndex
        self.activityIndicatorColor = activityIndicatorColor
        self.dismissButtonImage = dismissButtonImage
        self.dismissButtonPosition = dismissButtonPosition
        
        pageViewController = UIPageViewController(transitionStyle: .Scroll,
                                                  navigationOrientation: .Horizontal,
                                                  options: [UIPageViewControllerOptionInterPageSpacingKey : Constants.SpacingBetweenImages])

        super.init(nibName: nil, bundle: nil)
        
        setupPageViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Invalid initializer.")
    }
    
    // MARK: - Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDesign()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // HACK: UIKit doesn't animate status bar transition on iOS 9. So, manually animate it.
        if !viewDidAppear {
            viewDidAppear = true
            
            UIView.animateWithDuration(Constants.TransitionAnimationDuration) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (_) in
            self.pageViewController.view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            }, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return viewDidAppear
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }
    
    override func didReceiveMemoryWarning() {
        cachedRemoteImages = [:]
    }
    
    // MARK: - Private functions
    
    private func setupDesign() {
        view.backgroundColor = UIColor.blackColor()
        
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        didMoveToParentViewController(pageViewController)
        
        setupDismissButton()
        setupPanGestureRecognizer()
    }
    
    private func setupPageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Set up initial image view controller.
        if let imageViewController = imageViewController(forIndex: initialImageDisplayIndex) {
            pageViewController.setViewControllers([imageViewController],
                                                  direction: .Forward,
                                                  animated: false,
                                                  completion: nil)
        }
    }
    
    private func setupDismissButton() {
        let dismissButton = UIButton(type: .Custom)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setImage(dismissButtonImage, forState: .Normal)
        dismissButton.addTarget(self, action: #selector(AlbumViewController.didTapDismissButton(_:)), forControlEvents: .TouchUpInside)
        
        let xAnchorAttribute = dismissButtonPosition.xAnchorAttribute()
        let yAnchorAttribute = dismissButtonPosition.yAnchorAttribute()
        
        view.addSubview(dismissButton)
        
        view.addConstraint(
            NSLayoutConstraint(item: dismissButton,
                attribute: xAnchorAttribute,
                relatedBy: .Equal,
                toItem: view,
                attribute: xAnchorAttribute,
                multiplier: 1,
                constant: 0)
        )
        view.addConstraint(
            NSLayoutConstraint(item: dismissButton,
                attribute: yAnchorAttribute,
                relatedBy: .Equal,
                toItem: view,
                attribute: yAnchorAttribute,
                multiplier: 1,
                constant: 0)
        )
        view.addConstraint(
            NSLayoutConstraint(item: dismissButton,
                attribute: .Width,
                relatedBy: .Equal,
                toItem: nil,
                attribute: .NotAnAttribute,
                multiplier: 1,
                constant: Constants.DismissButtonDimension)
        )
        view.addConstraint(
            NSLayoutConstraint(item: dismissButton,
                attribute: .Height,
                relatedBy: .Equal,
                toItem: nil,
                attribute: .NotAnAttribute,
                multiplier: 1,
                constant: Constants.DismissButtonDimension)
        )
    }
    
    private func setupPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(AlbumViewController.didPan(_:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func imageViewController(forIndex index: Int) -> ImageViewController? {
        switch imageData {
        case .Local(let images):
            guard index >= 0 && index < images.count else {
                return nil
            }
            
            return ImageViewController(image: images[index], index: index)
        case .Remote(let urls, let imageDownloader):
            guard index >= 0 && index < urls.count else {
                return nil
            }
            
            let imageViewController = ImageViewController(activityIndicatorColor: activityIndicatorColor, index: index)
            let url = urls[index]
            
            if let image = cachedRemoteImages[url] {
                imageViewController.image = image
            } else {
                imageDownloader.downloadImageAtURL(url, completion: {
                    [weak self] (image) in
                    
                    self?.cachedRemoteImages[url] = image
                    imageViewController.image = image
                    })
            }
            
            return imageViewController
        }
    }
    
    @objc private func didTapDismissButton(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func didPan(sender: UIPanGestureRecognizer) {
        transitionController.didPan(withGestureRecognizer: sender, sourceView: view)
    }
    
}

// MARK: - Protocol conformance

// MARK: UIPageViewControllerDataSource

extension AlbumViewController: UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController,
                            viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let imageViewController = viewController as? ImageViewController else {
            return nil
        }
        
        return self.imageViewController(forIndex: imageViewController.index - 1)
    }
    
    func pageViewController(pageViewController: UIPageViewController,
                            viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let imageViewController = viewController as? ImageViewController else {
            return nil
        }
        
        return self.imageViewController(forIndex: imageViewController.index + 1)
    }
    
}

// MARK: UIPageViewControllerDelegate

extension AlbumViewController: UIPageViewControllerDelegate {
    
    func pageViewController(pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                                               previousViewControllers: [UIViewController],
                                               transitionCompleted completed: Bool) {
        guard completed == true else {
            return
        }
        
        if previousViewControllers.count > 0 {
            previousViewControllers
                .map { $0 as? ImageViewController }
                .forEach { $0?.resetImageView() }
        }
        
        if let currentImageIndex = currentImageViewController?.index {
            imageViewerDelegate?.imageViewerDidDisplayImage(atIndex: currentImageIndex)
        }
    }
    
}
