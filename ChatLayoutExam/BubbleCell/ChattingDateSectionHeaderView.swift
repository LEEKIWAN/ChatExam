//
//  ChattingDateSectionHeaderView.swift
//  Waiker
//
//  Created by 이기완 on 2022/08/10.
//

import UIKit

class ChattingDateSectionHeaderView: UICollectionReusableView {
    
    var date: Date? {
        didSet {
            updateUI()
        }
        
    }
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var containerView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        containerView.layer.borderColor = UIColor.green.cgColor
        containerView.layer.borderWidth = 0.5
    }
    

    func updateUI() {
        guard let date = date else { return }
        
        dateLabel.text = date.utcToDeviceLocal(format: ViewController.sectionDateFormat)
    }
}
