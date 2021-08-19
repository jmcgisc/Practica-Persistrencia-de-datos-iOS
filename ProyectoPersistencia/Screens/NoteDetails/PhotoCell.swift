//
//  PhotoCell.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 03/8/21.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet var photo: UIImageView?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photo?.image = nil
    }

    func configureViews(image: UIImage?) {
        photo?.image = image
    }
}
