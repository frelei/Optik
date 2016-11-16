//
//  ViewController.swift
//  Optik
//
//  Created by Htin Linn on 05/14/2016.
//  Copyright (c) 2016 Prolific Interactive. All rights reserved.
//

import UIKit
import Optik

internal final class ViewController: UIViewController {
    
    // MARK: - Private properties
    
    @IBOutlet fileprivate weak var localImagesButton: UIButton!
    
    fileprivate var currentLocalImageIndex = 0 {
        didSet {
            localImagesButton.setImage(localImages[currentLocalImageIndex], for: .normal)
        }
    }
    private let localImages: [UIImage] = [
        UIImage(named: "cats.jpg")!,
        UIImage(named: "super_blood_moon.jpg")!,
        UIImage(named: "life.jpg")!,
        UIImage(named: "whiteboard.jpg")!
    ]
    
    // MARK: - Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDesign()
    }
    
    // MARK: - Private functions
    
    private func setupDesign() {
        localImagesButton.imageView?.layer.cornerRadius = 5
        localImagesButton.imageView?.contentMode = .scaleAspectFill
    }

    @IBAction private func presentLocalImageViewer(_ sender: UIButton) {
        let viewController = Optik.imageViewer(withImages: localImages,
                                               initialImageDisplayIndex: currentLocalImageIndex,
                                               delegate: self)
        
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction private func presentRemoteImageViewer(_ sender: UIButton) {
        guard
            let url1 = URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/96/BURN_THE_WITCH.png"),
            let url2 = URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9b/Croissant%2C_cross_section.jpg"),
            let url3 = URL(string: "https://upload.wikimedia.org/wikipedia/en/9/9d/Link_%28Hyrule_Historia%29.png"),
            let url4 = URL(string: "https://upload.wikimedia.org/wikipedia/en/3/34/RickAstleyNeverGonnaGiveYouUp7InchSingleCover.jpg") else {
                return
        }
        
        let urls = [url1, url2, url3, url4]
        let imageDownloader = AlamofireImageDownloader()
        
        let viewController = Optik.imageViewer(withURLs: urls, initialImageDisplayIndex: 0, delegate: self, imageDownloader: imageDownloader, activityIndicatorColor: UIColor.white, dismissButtonImage: nil, dismissButtonPosition: .topLeading)
        present(viewController, animated: true, completion: nil)
    }

}

// MARK: - Protocol conformance

// MARK: ImageViewerDelegate

extension ViewController: ImageViewerDelegate {
    
    func transitionImageView(for index: Int) -> UIImageView {
        return localImagesButton.imageView!
    }
    
    func imageViewerDidDisplayImage(at index: Int) {
        currentLocalImageIndex = index
    }
    
    func actionButtonTapped(button: UIButton, at index: Int) {
        if  button.currentImage == UIImage(named: "heart-full")! {
            button.setImage(UIImage(named: "heart-empty"), for: .normal)
        } else {
            button.setImage(UIImage(named: "heart-full"), for: .normal)
        }
    }
    
    func imageForActionButton (at index: Int) -> UIImage {
        if index % 2 == 0 {
            return UIImage(named: "heart-full")!
        } else {
            return UIImage(named: "heart-empty")!
        }
    }
    
}
